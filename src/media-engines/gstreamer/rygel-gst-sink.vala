/*
 * Copyright (C) 2011 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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
using Gst.Base;

internal class Rygel.GstSink : Sink {
    public const string NAME = "http-gst-sink";
    public const string PAD_NAME = "sink";
    // High and low threshold for number of buffered chunks
    private const uint MAX_BUFFERED_CHUNKS = 32;
    private const uint MIN_BUFFERED_CHUNKS = 4;

    public Cancellable cancellable;

    private int priority;

    private int64 bytes_sent;
    private int64 max_bytes;

    private Mutex buffer_mutex = Mutex ();
    private Cond buffer_condition = Cond ();
    private unowned DataSource source;
    private HTTPSeekRequest offsets;

    private bool frozen;

    static construct {
        var caps = new Caps.any ();
        var template = new PadTemplate (PAD_NAME,
                                        PadDirection.SINK,
                                        PadPresence.ALWAYS,
                                        caps);
        add_pad_template (template);
    }

    public GstSink (DataSource source, HTTPSeekRequest? offsets) {
        this.bytes_sent = 0;
        this.max_bytes = int64.MAX;
        this.source = source;
        this.offsets = offsets;

        this.cancellable = new Cancellable ();

        this.sync = false;
        this.name = NAME;
        this.frozen = false;

        if (this.offsets != null && this.offsets is HTTPByteSeekRequest) {
            this.max_bytes = ((HTTPByteSeekRequest) this.offsets).total_size;
            if (this.max_bytes == -1) {
                this.max_bytes = int64.MAX;
            }
        }

        this.cancellable.cancelled.connect (this.on_cancelled);
    }

    public void freeze () {
        this.buffer_mutex.lock ();

        if (!this.frozen) {
            this.frozen = true;
        }

        this.buffer_mutex.unlock ();
    }

    public void thaw () {
        this.buffer_mutex.lock ();

        if (this.frozen) {
            this.frozen = false;
            this.buffer_condition.broadcast ();
        }

        this.buffer_mutex.unlock ();
    }

    public override FlowReturn render (Buffer buffer) {
        this.buffer_mutex.lock ();
        while (!this.cancellable.is_cancelled () &&
                this.frozen) {
            // Client is either not reading (Paused) or not fast enough
            this.buffer_condition.wait (this.buffer_mutex);
        }
        this.buffer_mutex.unlock ();

        if (this.cancellable.is_cancelled ()) {
            return FlowReturn.OK;
        }

        Idle.add_full (this.priority, () => {
            return this.push_data (buffer);
        });

        return FlowReturn.OK;
    }

    // Runs in application thread
    public bool push_data (Buffer buffer) {
        var left = this.max_bytes - this.bytes_sent;

        if (this.cancellable.is_cancelled () || left <= 0) {
            return false;
        }

        var bufsize = buffer.get_size ();
        var to_send = int64.min (bufsize, left);
        MapInfo info;

        buffer.map (out info, MapFlags.READ);

        unowned uint8[] tmp = info.data[0:to_send];

        this.source.data_available (tmp);
        this.bytes_sent += to_send;
        buffer.unmap (info);

        return false;
    }

    private void on_cancelled () {
        this.buffer_mutex.lock ();
        this.buffer_condition.broadcast ();
        this.buffer_mutex.unlock ();
    }
}
