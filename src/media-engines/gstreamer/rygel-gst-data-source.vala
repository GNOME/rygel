/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using Gst;

internal errordomain Rygel.GstDataSourceError {
    NOT_COMPATIBLE
}

internal class Rygel.GstDataSource : Rygel.DataSource, GLib.Object {
    internal dynamic Element src;
    private Pipeline pipeline;
    private HTTPSeek seek = null;
    private GstSink sink;
    private uint bus_watch_id;

    public GstDataSource (string uri) throws Error {
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

    public void start (HTTPSeek? offsets) throws Error {
        this.seek = offsets;
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
        Source.remove (this.bus_watch_id);
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
        }

        return ret;
    }

    private bool perform_seek () {
        if (this.seek != null &&
            this.seek.length >= this.seek.total_length) {
            return true;
        }

        var stop_type = Gst.SeekType.NONE;
        Format format;
        var flags = SeekFlags.FLUSH;
        int64 start, stop;

        if (this.seek.seek_type == HTTPSeekType.TIME) {
            format = Format.TIME;
            flags |= SeekFlags.KEY_UNIT;
            start = (this.seek.start) * Gst.USECOND;
            stop = (this.seek.stop) * Gst.USECOND;
        } else {
            format = Format.BYTES;
            flags |= SeekFlags.ACCURATE;
            start = this.seek.start;
            stop = this.seek.stop;
        }

        if (this.seek.stop > 0) {
            stop_type = Gst.SeekType.SET;
        }

        if (!this.pipeline.seek (1.0,
                                 format,
                                 flags,
                                 Gst.SeekType.SET,
                                 start,
                                 stop_type,
                                 stop + 1)) {
            warning (_("Failed to seek to offsets %lld:%lld"),
                     this.seek.start,
                     this.seek.stop);

            this.error (new DataSourceError.SEEK_FAILED (_("Failed to seek")));

            return false;
        }

        return true;
    }
}
