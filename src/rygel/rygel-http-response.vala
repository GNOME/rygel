/*
 * Copyright (C) 2008 Nokia Corporation.
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

internal class Rygel.HTTPResponse : GLib.Object, Rygel.StateMachine {
    public Soup.Server server { get; private set; }
    public Soup.Message msg;

    public Cancellable cancellable { get; set; }

    public HTTPSeek seek;

    private SourceFunc run_continue;
    private int _priority = -1;
    public int priority {
        get {
            if (this._priority != -1) {
                return this._priority;
            }

            var mode = this.msg.request_headers.get_one
                                        ("transferMode.dlna.org");

            if (mode == null || mode == "Interactive") {
                this._priority = Priority.DEFAULT;
            } else if (mode == "Streaming") {
                this._priority = Priority.HIGH;
            } else if (mode == "Background") {
                this._priority = Priority.LOW;
            } else {
                this._priority = Priority.DEFAULT;
            }

            return _priority;
        }
    }

    private Pipeline pipeline;
    private uint bus_watch_id;

    public HTTPResponse (HTTPGet        request,
                         HTTPGetHandler request_handler,
                         Element        src) throws Error {
        this.server = request.server;
        this.msg = request.msg;
        this.cancellable = request_handler.cancellable;
        this.seek = request.seek;

        var range = this.msg.request_headers.get_one("Range");
        if ((this.seek != null &&
            this.seek.length < this.seek.total_length) ||
            range != null) {
            this.msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            this.msg.set_status (Soup.KnownStatusCode.OK);
        }

        if (this.seek != null && this.seek is HTTPByteSeek) {
            this.msg.response_headers.set_encoding (Encoding.CONTENT_LENGTH);
        } else {
            this.msg.response_headers.set_encoding (Encoding.EOF);
        }

        if (this.cancellable != null) {
            this.cancellable.cancelled.connect (this.on_cancelled);
        }

        this.msg.response_body.set_accumulate (false);

        this.prepare_pipeline ("RygelHTTPGstResponse", src);
    }

    public async void run () {
        // Only bother attempting to seek if the offset is greater than zero.
        if (this.seek != null && this.seek.start > 0) {
            this.pipeline.set_state (State.PAUSED);
        } else {
            this.pipeline.set_state (State.PLAYING);
        }

        this.run_continue = run.callback;

        yield;
    }

    public void push_data (uint8[] data) {
        this.msg.response_body.append (Soup.MemoryUse.COPY, data);

        this.server.unpause_message (this.msg);
    }

    public virtual void end (bool aborted, uint status) {
        var sink = this.pipeline.get_by_name (HTTPGstSink.NAME) as HTTPGstSink;
        sink.cancellable.cancel ();

        this.pipeline.set_state (State.NULL);
        Source.remove (this.bus_watch_id);

        var encoding = this.msg.response_headers.get_encoding ();

        if (!aborted && encoding != Encoding.CONTENT_LENGTH) {
            this.msg.response_body.complete ();
            this.server.unpause_message (this.msg);
        }

        if (this.run_continue != null) {
            this.run_continue ();
        }

        if (status != Soup.KnownStatusCode.NONE) {
            this.msg.set_status (status);
        }

        this.completed ();
    }

    private void on_cancelled (Cancellable cancellable) {
        this.end (true, Soup.KnownStatusCode.CANCELLED);
    }

    private void prepare_pipeline (string name, Element src) throws Error {
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
        this.bus_watch_id = bus.add_watch (this.bus_handler);
    }

    private void src_pad_added (Element src, Pad src_pad) {
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

    private bool bus_handler (Gst.Bus bus, Gst.Message message) {
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
        var stop_type = Gst.SeekType.NONE;
        Format format;

        if (this.seek is HTTPTimeSeek) {
            format = Format.TIME;

            if (this.seek.stop > 0) {
                stop_type = Gst.SeekType.SET;
            }
        } else {
            format = Format.BYTES;
        }

        if (!this.pipeline.seek (1.0,
                                 format,
                                 SeekFlags.FLUSH | SeekFlags.ACCURATE,
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
