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
    public Format format { get; private set; }

    public int64 start { get; private set; }
    public int64 stop { get; private set; }

    public int64 length {
        get {
            return this.stop + 1 - this.start;
        }
    }

    public HTTPSeek (Format format,
                     int64  start,
                     int64  stop) {
        this.format = format;
        this.start = start;
        this.stop = stop;
    }

    public static HTTPSeek? from_byte_range (Soup.Message msg)
                                             throws HTTPSeekError {
        string range, pos;
        string[] range_tokens;
        int64 start = 0, stop = -1;

        range = msg.request_headers.get ("Range");
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

        // Get last byte position if specified
        pos = range_tokens[1];
        if (pos[0].isdigit ()) {
            stop = pos.to_int64 ();
            if (stop < start) {
                throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }
        } else if (pos != "") {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        return new HTTPSeek (Format.BYTES, start, stop);
    }

    public static HTTPSeek? from_time_range (Soup.Message msg)
                                             throws HTTPSeekError {
        string range, time;
        string[] range_tokens;
        int64 start = 0, stop = -1;

        range = msg.request_headers.get ("TimeSeekRange.dlna.org");
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
        } else if (time != "") {
            throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'", range);
        }

        return new HTTPSeek (Format.TIME, start, stop);
    }

    public void add_response_header (Soup.Message msg, int64 length=-1) {
        string value;

        if (this.format == Format.TIME) {
            // TimeSeekRange.dlna.org: npt=START_TIME-END_TIME
            value = "npt=%g-".printf ((double) this.start / SECOND);
            if (this.stop > 0) {
                value += "%g".printf ((double) this.stop / SECOND);
            }

            msg.response_headers.append ("TimeSeekRange.dlna.org", value);
        } else {
            // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
            value = "bytes " + this.start.to_string () + "-";
            var end_point = this.stop;

            if (length > 0) {
                if (end_point >= 0) {
                    end_point = int64.max (end_point, length - 1);
                } else {
                    end_point = length - 1;
                }
            }

            if (end_point >= 0)
                value += end_point.to_string();
            }

            if (length > 0) {
                value += "/" + length.to_string();
            }

            msg.response_headers.append ("Content-Range", value);
        }
    }
}
