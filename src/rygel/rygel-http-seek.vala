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

internal errordomain Rygel.HTTPSeekError {
    INVALID_RANGE = Soup.KnownStatusCode.BAD_REQUEST,
    OUT_OF_RANGE = Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE,
}

internal class Rygel.HTTPSeek : GLib.Object {
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

    public static HTTPSeek? from_byte_range (HTTPRequest request)
                                             throws HTTPSeekError {
        string range, pos;
        string[] range_tokens;
        int64 start = 0, stop = -1;

        range = request.msg.request_headers.get ("Range");
        if (range == null) {
            return null;
        }

        // We have a Range header. Parse.
        if (!range.has_prefix ("bytes=")) {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        range_tokens = range.offset (6).split ("-", 2);
        if (range_tokens[0] == null || range_tokens[1] == null) {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        // Get first byte position
        pos = range_tokens[0];
        if (pos[0].isdigit ()) {
            start = pos.to_int64 ();
        } else if (pos  != "") {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        int64 length;
        if (request.thumbnail != null) {
            length = request.thumbnail.size;
        } else {
            length = request.item.size;
        }

        // Get last byte position if specified
        pos = range_tokens[1];
        if (pos[0].isdigit ()) {
            stop = pos.to_int64 ();
            if (stop < start) {
                throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }
        } else if (pos == "") {
            stop = length - 1;
        } else {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        return new HTTPSeek (request.msg,
                             Format.BYTES,
                             start,
                             stop,
                             length);
    }

    // FIXME: We are only accepting time range in this format:
    //
    // TimeSeekRange.dlna.org : npt=417.33-779.09
    //
    // and not
    //
    // TimeSeekRange.dlna.org : npt=10:19:25.7-13:23:33.6
    public static HTTPSeek? from_time_range (HTTPRequest request)
                                             throws HTTPSeekError {
        string range, time;
        string[] range_tokens;
        int64 start = 0, stop = -1;

        range = request.msg.request_headers.get ("TimeSeekRange.dlna.org");
        if (range == null) {
            return null;
        }

        if (!range.has_prefix ("npt=")) {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        range_tokens = range.offset (4).split ("-", 2);
        if (range_tokens[0] == null || range_tokens[1] == null) {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        // Get start time
        time = range_tokens[0];
        if (time[0].isdigit ()) {
            start = (int64) (time.to_double () * SECOND);
        } else if (time != "") {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        // Get end time
        time = range_tokens[1];
        if (time[0].isdigit()) {
            stop = (int64) (time.to_double () * SECOND);
            if (stop < start) {
                throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }
        } else if (time == "") {
            stop = request.item.duration - 1;
        } else {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        return new HTTPSeek (request.msg,
                             Format.TIME,
                             start,
                             stop,
                             request.item.duration);
    }

    public void add_response_headers () {
        string header;
        string value;
        double start = 0;
        double stop;

        if (this.format == Format.TIME) {
            // TimeSeekRange.dlna.org: npt=START_TIME-END_TIME/DURATION
            header = "TimeSeekRange.dlna.org";
            value = "npt=";
            start = (double) this.start / SECOND;
            stop = (double) this.stop / SECOND;
        } else {
            // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
            header = "Content-Range";
            value = "bytes ";
            start = (double) this.start;
            stop = (double) this.stop;

        }

        value += start.to_string () + "-";

        if (stop >= 0.0) {
            value += stop.to_string ();
        }

        if (this.length > 0) {
            value += "/" + this.length.to_string ();
        } else {
            value += "/*";
        }

        this.msg.response_headers.append (header, value);
        this.msg.response_headers.set_content_length (this.length);
    }
}
