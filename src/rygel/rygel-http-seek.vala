/*
 * Copyright (C) 2008-2009 Nokia Corporation.
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

internal errordomain Rygel.HTTPSeekError {
    INVALID_RANGE = Soup.KnownStatusCode.BAD_REQUEST,
    OUT_OF_RANGE = Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE,
}

internal abstract class Rygel.HTTPSeek : GLib.Object {
    public Soup.Message msg { get; private set; }
    public Format format { get; private set; }

    // These are either number of bytes or microseconds
    public int64 start { get; private set; }
    public int64 stop { get; private set; }
    public int64 length { get; private set; }

    public HTTPSeek (Soup.Message msg,
                     Format       format,
                     int64        start,
                     int64        stop,
                     int64        length) {
        this.msg = msg;
        this.format = format;
        this.start = start;
        this.stop = stop;
        this.length = length;

        if (length > 0) {
            this.stop = stop.clamp (start + 1, length - 1);
        }
    }

    public abstract void add_response_headers ();
}
