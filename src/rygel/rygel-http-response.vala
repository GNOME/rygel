/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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

internal abstract class Rygel.HTTPResponse : GLib.Object, Rygel.StateMachine {
    public Soup.Server server { get; private set; }
    protected Soup.Message msg;

    protected Cancellable cancellable;

    public HTTPResponse (Soup.Server  server,
                         Soup.Message msg,
                         bool         partial) {
        this.server = server;
        this.msg = msg;

        if (partial) {
            this.msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            this.msg.set_status (Soup.KnownStatusCode.OK);
        }

        this.msg.response_body.set_accumulate (false);

        this.server.request_aborted += on_request_aborted;
    }

    public virtual void run (Cancellable? cancellable) {
        if (cancellable != null) {
            this.cancellable = cancellable;
            cancellable.cancelled += this.on_cancelled;
        }
    }

    private void on_cancelled (Cancellable cancellable) {
        this.end (true, Soup.KnownStatusCode.CANCELLED);
    }

    private void on_request_aborted (Soup.Server        server,
                                     Soup.Message       msg,
                                     Soup.ClientContext client) {
        // Ignore if message isn't ours
        if (msg == this.msg)
            this.end (true, Soup.KnownStatusCode.NONE);
    }

    public void push_data (void *data, size_t length) {
        this.msg.response_body.append (Soup.MemoryUse.COPY,
                                       data,
                                       length);

        this.server.unpause_message (this.msg);
    }

    public virtual void end (bool aborted, uint status) {
        if (status != Soup.KnownStatusCode.NONE) {
            this.msg.set_status (status);
        }

        this.completed ();
    }
}

internal class Rygel.Seek : GLib.Object {
    public Format format { get; private set; }

    private int64 _start;
    public int64 start {
        get {
            return this._start;
        }
        set {
            this._start = value;
            this.length = stop - start + 1;
        }
    }

    private int64 _stop;
    public int64 stop {
        get {
            return this._stop;
        }
        set {
            this._stop = value;
            this.length = stop - start + 1;
        }
    }

    public int64 length { get; private set; }

    public Seek (Format format,
                 int64  start,
                 int64  stop) {
        this.format = format;
        this.start = start;
        this.stop = stop;
    }
}
