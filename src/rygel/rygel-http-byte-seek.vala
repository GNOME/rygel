/*
 * Copyright (C) 2009 Nokia Corporation.
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

internal class Rygel.HTTPByteSeek : Rygel.HTTPSeek {
    public HTTPByteSeek (HTTPGet request) throws HTTPSeekError {
        string range, pos;
        string[] range_tokens;
        int64 start = 0, total_length;

        if (request.thumbnail != null) {
            total_length = request.thumbnail.size;
        } else if (request.subtitle != null) {
            total_length = request.subtitle.size;
        } else {
            total_length = request.item.size;
        }
        var stop = total_length - 1;

        range = request.msg.request_headers.get ("Range");
        if (range != null) {
            // We have a Range header. Parse.
            if (!range.has_prefix ("bytes=")) {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            range_tokens = range.offset (6).split ("-", 2);
            if (range_tokens[0] == null || range_tokens[1] == null) {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            // Get first byte position
            pos = range_tokens[0];
            if (pos[0].isdigit ()) {
                start = pos.to_int64 ();
            } else if (pos  != "") {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            // Get last byte position if specified
            pos = range_tokens[1];
            if (pos[0].isdigit ()) {
                stop = pos.to_int64 ();
                if (stop < start) {
                    throw new HTTPSeekError.INVALID_RANGE (
                                        _("Invalid Range '%s'"),
                                        range);
                }
            } else if (pos != "") {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }
        }

        base (request.msg,
              start,
              stop,
              total_length);
    }

    public static bool needed (HTTPGet request) {
        return (request.item.size > 0 &&
                request.handler is HTTPIdentityHandler) ||
               (request.thumbnail != null && request.thumbnail.size > 0) ||
               (request.subtitle != null && request.subtitle.size > 0);
    }

    public override void add_response_headers () {
        // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
        var range = "bytes ";
        unowned Soup.MessageHeaders headers = this.msg.response_headers;

        headers.append ("Accept-Ranges", "bytes");

        range += this.start.to_string () + "-" +
                 this.stop.to_string () + "/" +
                 this.length.to_string ();
        headers.append ("Content-Range", range);

        headers.set_content_length (this.stop + 1 - this.start);
    }
}
