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

internal class Rygel.HTTPGstResponse : Rygel.HTTPResponse {
    private const string SINK_NAME = "fakesink";
    // High and low threshold for number of buffered chunks
    private const uint MAX_BUFFERED_CHUNKS = 32;
    private const uint MIN_BUFFERED_CHUNKS = 4;

    private Pipeline pipeline;

    private HTTPSeek seek;

    private int64 buffered;
    private bool out_of_sync;

    public HTTPGstResponse (Soup.Server  server,
                            Soup.Message msg,
                            string       name,
                            Element      src,
                            HTTPSeek?    seek,
                            Cancellable? cancellable) throws Error {
        base (server, msg, false, cancellable);

        this.msg.response_headers.set_encoding (Soup.Encoding.EOF);

        this.prepare_pipeline (name, src);
        this.seek = seek;

        this.buffered = 0;
        this.out_of_sync = false;
    }

    public override async void run () {
        this.msg.wrote_chunk.connect (this.on_wrote_chunk);

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
        this.pipeline.set_state (State.NULL);
        this.msg.wrote_chunk.disconnect (this.on_wrote_chunk);

        if (!aborted) {
            this.msg.response_body.complete ();
            this.server.unpause_message (this.msg);
        }

        base.end (aborted, status);
    }

    private void prepare_pipeline (string name,
                                   Element src) throws Error {
        dynamic Element sink = ElementFactory.make ("fakesink", SINK_NAME);

        if (sink == null) {
            // 'fakesink' should not be translated
            throw new GstError.MISSING_PLUGIN (_("Plugin 'fakesink' missing"));
        }

        sink.signal_handoffs = true;
        sink.handoff.connect (this.on_new_buffer);

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

        var sink = this.pipeline.get_by_name (SINK_NAME);
        Pad sink_pad;

        dynamic Element depay = GstUtils.get_rtp_depayloader (caps);
        if (depay != null) {
            this.pipeline.add (depay);
            if (!depay.link (sink)) {
                critical (_("Failed to link %s to %s"),
                          depay.name,
                          sink.name);
                this.end (false, Soup.KnownStatusCode.NONE);
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
            this.end (false, Soup.KnownStatusCode.NONE);
            return;
        }

        if (depay != null) {
            depay.sync_state_with_parent ();
        }
    }

    private void on_new_buffer (Element sink,
                                Buffer  buffer,
                                Pad     pad) {
        Idle.add_full (this.priority, () => {
            if (this.cancellable.is_cancelled ()) {
                return false;
            }

            this.push_data (buffer.data);
            this.buffered++;

            if (this.buffered > MAX_BUFFERED_CHUNKS) {
                // Client is either not reading (Paused) or not fast enough
                this.pipeline.set_state (State.PAUSED);
                this.out_of_sync = true;
            }

            return false;
        });
    }

    private void on_wrote_chunk (Soup.Message msg) {
        this.buffered--;

        if (out_of_sync && this.buffered < MIN_BUFFERED_CHUNKS) {
            this.pipeline.set_state (State.PLAYING);
            this.out_of_sync = false;
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
                    this.end (false, Soup.KnownStatusCode.NONE);

                    return false;
                });
        }

        return ret;
    }

    private bool perform_seek () {
        Gst.SeekType stop_type;

        if (this.seek.stop > 0) {
            stop_type = Gst.SeekType.SET;
        } else {
            stop_type = Gst.SeekType.NONE;
        }

        if (!this.pipeline.seek (1.0,
                                 Format.TIME,
                                 SeekFlags.FLUSH,
                                 Gst.SeekType.SET,
                                 this.seek.start,
                                 stop_type,
                                 this.seek.stop)) {
            warning (_("Failed to seek to offset %lld"), this.seek.start);

            this.end (false,
                      Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE);

            return false;
        }

        return true;
    }
}

