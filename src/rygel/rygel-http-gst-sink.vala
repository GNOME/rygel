/*
 * Copyright (C) 2011 Nokia Corporation.
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

internal class Rygel.HTTPGstSink : BaseSink {
    public const string NAME = "http-gst-sink";
    public const string PAD_NAME = "sink";
    // High and low threshold for number of buffered chunks
    private const uint MAX_BUFFERED_CHUNKS = 32;
    private const uint MIN_BUFFERED_CHUNKS = 4;

    public Cancellable cancellable;

    private unowned HTTPGstResponse response;
    private int priority;

    private int64 chunks_buffered;
    private int64 bytes_sent;
    private int64 max_bytes;

    private Mutex buffer_mutex;
    private Cond buffer_condition;

    private bool render_preroll;

    static construct {
        var caps = new Caps.any ();
        var template = new PadTemplate (PAD_NAME,
                                        PadDirection.SINK,
                                        PadPresence.ALWAYS,
                                        caps);
        add_pad_template (template);
    }

    public HTTPGstSink (HTTPGstResponse response) {
        this.chunks_buffered = 0;
        this.bytes_sent = 0;
        this.max_bytes = int64.MAX;
        this.buffer_mutex = new Mutex ();
        this.buffer_condition = new Cond ();

        this.cancellable = new Cancellable ();
        this.priority = response.priority;
        this.response = response;

        this.sync = false;
        this.name = NAME;

        if (response.seek != null) {
            if (response.seek is HTTPByteSeek) {
                this.max_bytes = response.seek.length;
            }

            this.render_preroll = false;
        } else {
            this.render_preroll = true;
        }

        this.cancellable.cancelled.connect (this.on_cancelled);
        response.msg.wrote_chunk.connect (this.on_wrote_chunk);
    }

    ~HTTPGstSink () {
        this.response.msg.wrote_chunk.disconnect (this.on_wrote_chunk);
    }

    public override FlowReturn preroll (Buffer buffer) {
        if (this.render_preroll) {
            return render (buffer);
        } else {
            // If we are seeking, we must not send out first prerolled buffers
            // since seek event is sent to pipeline after it is in PAUSED state
            // already and preroll has already happened. i-e we will be always
            // sending out the beginning of the media if we execute the first
            // preroll.
            this.render_preroll = true;

            return FlowReturn.OK;
        }
    }

    public override FlowReturn render (Buffer buffer) {
        this.buffer_mutex.lock ();
        while (!this.cancellable.is_cancelled () &&
               this.chunks_buffered > MAX_BUFFERED_CHUNKS) {
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

        var to_send = int64.min (buffer.size, left);

        this.response.push_data (buffer.data[0:to_send]);
        this.chunks_buffered++;
        this.bytes_sent += to_send;

        return false;
    }

    private void on_wrote_chunk (Soup.Message msg) {
        this.buffer_mutex.lock ();
        this.chunks_buffered--;

        if (this.chunks_buffered < MIN_BUFFERED_CHUNKS) {
            this.buffer_condition.broadcast ();
        }
        this.buffer_mutex.unlock ();
    }

    private void on_cancelled () {
        this.buffer_mutex.lock ();
        this.buffer_condition.broadcast ();
        this.buffer_mutex.unlock ();
    }
}

