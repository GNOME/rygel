/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Prasanna Modem <prasanna@ecaspia.com>
 *         Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gst;

internal errordomain Rygel.GstDataSourceError {
    NOT_COMPATIBLE
}

internal class Rygel.GstDataSource : Rygel.DataSource, GLib.Object {
    internal dynamic Element src;
    internal MediaResource res;
    private Pipeline pipeline;
    private HTTPSeekRequest seek = null;
    private GstSink sink;
    private uint bus_watch_id;
    string uri = null;

    public GstDataSource (string uri, MediaResource ? resource) throws Error {
        this.uri = uri;
        this.res = resource;
        this.src = GstUtils.create_source_for_uri (uri);
        if (this.src == null) {
            var msg = _("Could not create GstElement for URI %s");

            throw new GstDataSourceError.NOT_COMPATIBLE (msg, uri);
        }
    }

    ~GstDataSource () {
        if (this.sink != null) {
            this.sink.cancellable.cancel ();
        }

        if (this.pipeline != null) {
            this.pipeline.set_state (State.NULL);
        }
    }

    public GstDataSource.from_element (Element element) {
        this.src = element;
    }

    public string get_uri () {
        return this.uri;
    }

    public virtual Gee.List<HTTPResponseElement>? preroll
                                        (HTTPSeekRequest? seek_request,
                                         PlaySpeedRequest? playspeed_request)
                                         throws Error {
        var response_list = new Gee.ArrayList<HTTPResponseElement> ();

        if (playspeed_request != null) {
            throw new DataSourceError.PLAYSPEED_FAILED
                                    (_("Playspeed not supported"));
        }

        if (seek_request == null) {
            debug("No seek requested - sending entire binary");
        } else if (seek_request is HTTPByteSeekRequest) {
            // Supported - and no reponse values required...
            var seek_response = new HTTPByteSeekResponse.from_request
                                        (seek_request as HTTPByteSeekRequest);
            debug ("Processing byte seek request for bytes %lld-%lld",
                   seek_response.start_byte,
                   seek_response.end_byte);
            response_list.add (seek_response);
        } else if (seek_request is HTTPTimeSeekRequest) {
            var time_seek = seek_request as HTTPTimeSeekRequest;
            // Set the effective TimeSeekRange response range to the requested
            // range
            // TODO: Align this with actual time range being returned, might
            // not be possible as we would need to seek before handling the
            // response
            var seek_response = new HTTPTimeSeekResponse.from_request
                                        (time_seek,
                                         res.duration * TimeSpan.SECOND);
            debug ("Processing time seek request for %lldms-%lldms",
                   seek_response.start_time,
                   seek_response.end_time);
            response_list.add (seek_response);
        } else {
            // Unknown/unsupported seek type
            throw new DataSourceError.SEEK_FAILED
                                    (_("HTTPSeekRequest type %s unsupported"),
                                     seek_request.get_type (). name ());
        }

        this.seek = seek_request;

        return response_list;
    }

    public void start () throws Error {
        this.prepare_pipeline ("RygelGstDataSource", this.src);
        if (this.seek != null) {
            this.pipeline.set_state (State.PAUSED);
        } else {
            this.pipeline.set_state (State.PLAYING);
        }
    }

    public void freeze () {
        this.sink.freeze ();
    }

    public void thaw () {
        this.sink.thaw ();
    }

    public void stop () {
        // Unlock eventually frozen sink
        this.sink.cancellable.cancel ();
        this.pipeline.set_state (State.NULL);
        if (this.bus_watch_id != 0) {
            Source.remove (this.bus_watch_id);
            this.bus_watch_id = 0;
        }
        Idle.add ( () => { this.done (); return false; });
    }

    private void prepare_pipeline (string   name,
                                   Element  src) throws Error {
        this.sink = new GstSink (this, this.seek);

        this.pipeline = new Pipeline (name);
        if (pipeline == null) {
            throw new DataSourceError.GENERAL
                                        (_("Failed to create pipeline"));
        }

        this.pipeline.add_many (src, sink);

        if (src.numsrcpads == 0) {
            // Seems source uses dynamic pads, link when pad available
            src.pad_added.connect (this.src_pad_added);
        } else {
            // static pads? easy!
            if (!src.link (sink)) {
                throw new GstError.LINK (_("Failed to link %s to %s"),
                                         src.name,
                                         sink.name);
            }
        }

        // Bus handler
        var bus = this.pipeline.get_bus ();
        this.bus_watch_id = bus.add_watch (Priority.DEFAULT, this.bus_handler);
    }

    private void src_pad_added (Element src, Pad src_pad) {
        var caps = src_pad.query_caps (null);

        var sink = this.pipeline.get_by_name (GstSink.NAME);
        Pad sink_pad;

        dynamic Element depay = GstUtils.get_rtp_depayloader (caps);
        if (depay != null) {
            this.pipeline.add (depay);
            if (!depay.link (sink)) {
                critical (_("Failed to link %s to %s"),
                          depay.name,
                          sink.name);
                this.done ();

                return;
            }

            sink_pad = depay.get_compatible_pad (src_pad, caps);
        } else {
            sink_pad = sink.get_compatible_pad (src_pad, caps);
        }

        if (src_pad.link (sink_pad) != PadLinkReturn.OK) {
            critical (_("Failed to link pad %s to %s"),
                      src_pad.name,
                      sink_pad.name);
            this.done ();

            return;
        }

        if (depay != null) {
            depay.sync_state_with_parent ();
        }
    }

    private bool bus_handler (Gst.Bus bus, Gst.Message message) {
        bool ret = true;

        if (message.type == MessageType.EOS) {
            ret = false;
        } else if (message.type == MessageType.STATE_CHANGED) {
            if (message.src != this.pipeline) {
                return true;
            }

            State old_state;
            State new_state;

            message.parse_state_changed (out old_state,
                                         out new_state,
                                         null);

            if (old_state == State.NULL && new_state == State.READY) {
                dynamic Element element = this.pipeline.get_by_name ("muxer");
                if (element != null) {
                    var name = element.get_factory ().get_name ();
                    // Awesome gross hack, really.
                    if (name == "mp4mux") {
                        element.streamable = true;
                        element.fragment_duration = 1000;
                    }
                }
            }

            var filename = "rygel_media_engine_%d_%d".printf (old_state,
                                                               new_state);
            Debug.bin_to_dot_file_with_ts (this.pipeline,
                                           DebugGraphDetails.ALL,
                                           filename);

            if (this.seek != null) {
                if (old_state == State.READY && new_state == State.PAUSED) {
                    if (this.perform_seek ()) {
                        this.pipeline.set_state (State.PLAYING);
                    }
                }
            }
        } else {
            GLib.Error err;
            string err_msg;

            if (message.type == MessageType.ERROR) {
                Debug.bin_to_dot_file_with_ts (this.pipeline,
                                               DebugGraphDetails.ALL,
                                               "rygel_media_engine_error");

                message.parse_error (out err, out err_msg);
                critical (_("Error from pipeline %s: %s"),
                          this.pipeline.name,
                          err_msg);

                ret = false;
            } else if (message.type == MessageType.WARNING) {
                message.parse_warning (out err, out err_msg);
                warning (_("Warning from pipeline %s: %s"),
                         this.pipeline.name,
                         err_msg);
            }
        }

        if (!ret) {
            Idle.add_full (Priority.DEFAULT, () => {
                this.done ();

                return false;
            });

            this.bus_watch_id = 0;
        }

        return ret;
    }

    public virtual bool perform_seek () {
        var stop_type = Gst.SeekType.NONE;
        Format format;
        var flags = SeekFlags.FLUSH;
        int64 start, stop;

        if (this.seek is HTTPTimeSeekRequest) {
            var time_seek = this.seek as HTTPTimeSeekRequest;
            format = Format.TIME;
            flags |= SeekFlags.KEY_UNIT;
            start = time_seek.start_time * Gst.USECOND;
            // Work-around for https://bugzilla.gnome.org/show_bug.cgi?id=762787
            if (this.src.name == "dvdreadsrc" && start == 0) {
                start += 1 * Gst.SECOND;
            }
            stop = time_seek.end_time * Gst.USECOND;
            debug ("Performing time-range seek: %lldns to %lldns", start, stop);
        } else if (this.seek is HTTPByteSeekRequest) {
            var byte_seek = this.seek as HTTPByteSeekRequest;
            if (byte_seek.range_length >= byte_seek.total_size) {
                // Can happen on (invalid) seeks on resources with unspecified
                // size
                return true;
            }

            format = Format.BYTES;
            flags |= SeekFlags.ACCURATE;
            start = byte_seek.start_byte;
            stop = byte_seek.end_byte;
            debug ("Performing byte-range seek: bytes %lld to %lld",
                   start,
                   stop);
        } else {
            var result = new DataSourceError.SEEK_FAILED
                                        (_("Unsupported seek type"));
            this.error (result);

            return false;
        }

        if (stop > 0) {
            stop_type = Gst.SeekType.SET;
        }

        if (!this.pipeline.seek (1.0,
                                 format,
                                 flags,
                                 Gst.SeekType.SET,
                                 start,
                                 stop_type,
                                 stop + 1)) {
            warning (_("Failed to seek to offsets %lld:%lld"), start, stop);

            this.error (new DataSourceError.SEEK_FAILED (_("Failed to seek")));

            return false;
        }

        return true;
    }
}
