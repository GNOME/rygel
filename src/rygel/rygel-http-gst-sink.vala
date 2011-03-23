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

    private int64 buffered;

    private Mutex buffer_mutex;
    private Cond buffer_condition;

    static construct {
        var caps = new Caps.any ();
        var template = new PadTemplate (PAD_NAME,
                                        PadDirection.SINK,
                                        PadPresence.ALWAYS,
                                        caps);
        add_pad_template (template);
    }

    public HTTPGstSink (HTTPGstResponse response) {
        this.buffered = 0;
        this.buffer_mutex = new Mutex ();
        this.buffer_condition = new Cond ();

        this.cancellable = new Cancellable ();
        this.priority = response.priority;
        this.response = response;

        this.sync = false;
        this.name = NAME;

        this.cancellable.cancelled.connect (this.on_cancelled);
        response.msg.wrote_chunk.connect (this.on_wrote_chunk);
    }

    ~HTTPGstSink () {
        this.response.msg.wrote_chunk.disconnect (this.on_wrote_chunk);
    }

    public override FlowReturn preroll (Buffer buffer) {
        return render (buffer);
    }

    public override FlowReturn render (Buffer buffer) {
        this.buffer_mutex.lock ();
        while (!this.cancellable.is_cancelled () &&
               this.buffered > MAX_BUFFERED_CHUNKS) {
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
        if (this.cancellable.is_cancelled ()) {
            return false;
        }

        this.response.push_data (buffer.data);
        this.buffered++;

        return false;
    }

    private void on_wrote_chunk (Soup.Message msg) {
        this.buffer_mutex.lock ();
        this.buffered--;

        if (this.buffered < MIN_BUFFERED_CHUNKS) {
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

