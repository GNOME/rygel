/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008,2011 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Soup;

internal class Rygel.HTTPGstResponse : Rygel.HTTPResponse {
    private Pipeline pipeline;

    public HTTPSeek seek;

    public HTTPGstResponse (HTTPGet        request,
                            HTTPGetHandler request_handler,
                            Element?       gst_src = null) throws Error {
        base (request, request_handler, false);
        var src = gst_src;
        if (src == null) {
            src = request.item.create_stream_source ();

            if (src == null) {
                throw new HTTPRequestError.NOT_FOUND (_("Not found"));
            }
        }

        this.seek = request.seek;
        this.prepare_pipeline ("RygelHTTPGstResponse", src);

        if (this.seek != null && this.seek is HTTPByteSeek) {
            this.msg.response_headers.set_encoding (Encoding.CONTENT_LENGTH);
        } else {
            this.msg.response_headers.set_encoding (Encoding.EOF);
        }
    }

    public override async void run () {
        // Only bother attempting to seek if the offset is greater than zero.
        if (this.seek != null && this.seek.start > 0) {
            this.pipeline.set_state (State.PAUSED);
        } else {
            this.pipeline.set_state (State.PLAYING);
        }

        this.run_continue = run.callback;

        yield;
    }

    public override void end (bool aborted, uint status) {
        var sink = this.pipeline.get_by_name (HTTPGstSink.NAME) as HTTPGstSink;
        sink.cancellable.cancel ();

        this.pipeline.set_state (State.NULL);

        var encoding = this.msg.response_headers.get_encoding ();

        if (!aborted && encoding != Encoding.CONTENT_LENGTH) {
            this.msg.response_body.complete ();
            this.server.unpause_message (this.msg);
        }

        base.end (aborted, status);
    }

    private void prepare_pipeline (string name,
                                   Element src) throws Error {
        var sink = new HTTPGstSink (this);

        this.pipeline = new Pipeline (name);
        assert (this.pipeline != null);

        this.pipeline.add_many (src, sink);

        if (src.numpads == 0) {
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
        bus.add_watch (bus_handler);
    }

    private void src_pad_added (Element src,
                                Pad     src_pad) {
        var caps = src_pad.get_caps ();

        var sink = this.pipeline.get_by_name (HTTPGstSink.NAME);
        Pad sink_pad;

        dynamic Element depay = GstUtils.get_rtp_depayloader (caps);
        if (depay != null) {
            this.pipeline.add (depay);
            if (!depay.link (sink)) {
                critical (_("Failed to link %s to %s"),
                          depay.name,
                          sink.name);
                this.end (false, KnownStatusCode.NONE);
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
            this.end (false, KnownStatusCode.NONE);
            return;
        }

        if (depay != null) {
            depay.sync_state_with_parent ();
        }
    }

    private bool bus_handler (Gst.Bus     bus,
                              Gst.Message message) {
        bool ret = true;

        if (message.type == MessageType.EOS) {
            ret = false;
        } else if (message.type == MessageType.STATE_CHANGED) {
            if (message.src != this.pipeline) {
                return true;
            }

            if (this.seek != null && this.seek.start > 0) {
                State old_state;
                State new_state;

                message.parse_state_changed (out old_state,
                                             out new_state,
                                             null);

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
                Idle.add_full (this.priority, () => {
                    this.end (false, KnownStatusCode.NONE);

                    return false;
                });
        }

        return ret;
    }

    private bool perform_seek () {
        Gst.SeekType stop_type;
        Format format;

        if (this.seek is HTTPTimeSeek) {
            format = Format.TIME;
        } else {
            format = Format.BYTES;
        }

        if (this.seek.stop > 0) {
            stop_type = Gst.SeekType.SET;
        } else {
            stop_type = Gst.SeekType.NONE;
        }

        if (!this.pipeline.seek (1.0,
                                 format,
                                 SeekFlags.FLUSH,
                                 Gst.SeekType.SET,
                                 this.seek.start,
                                 stop_type,
                                 this.seek.stop)) {
            warning (_("Failed to seek to offset %lld"), this.seek.start);

            this.end (false, KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE);

            return false;
        }

        return true;
    }
}

