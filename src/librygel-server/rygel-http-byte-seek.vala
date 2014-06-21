/*
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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
        Soup.Range[] ranges;
        int64 start = 0, total_length;
        unowned string range = request.msg.request_headers.get_one ("Range");

        if (request.thumbnail != null) {
            total_length = request.thumbnail.size;
        } else if (request.subtitle != null) {
            total_length = request.subtitle.size;
        } else {
            total_length = (request.object as MediaFileItem).size;
        }
        var stop = total_length - 1;

        if (range != null) {
            if (request.msg.request_headers.get_ranges (total_length,
                                                        out ranges)) {
                // TODO: Somehow deal with multipart/byterange properly
                start = ranges[0].start;
                stop = ranges[0].end;
            } else {
                // Range header was present but invalid
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            if (start > stop) {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }
        }

        base (request.msg, start, stop, 1, total_length);
        this.seek_type = HTTPSeekType.BYTE;
    }

    public static bool needed (HTTPGet request) {
        bool force_seek = false;

        try {
            var hack = ClientHacks.create (request.msg);
            force_seek = hack.force_seek ();
        } catch (Error error) { }

        return force_seek || (!(request.object is MediaContainer) &&
                ((request.object as MediaFileItem).size > 0 &&
                request.handler is HTTPIdentityHandler) ||
               (request.thumbnail != null &&
                request.thumbnail.size > 0) ||
               (request.subtitle != null && request.subtitle.size > 0));
    }

    public static bool requested (HTTPGet request) {
        return request.msg.request_headers.get_one ("Range") != null;
    }

    public override void add_response_headers () {
        // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
        var range = "bytes ";
        unowned Soup.MessageHeaders headers = this.msg.response_headers;

        if (this.msg.request_headers.get_one ("Range") != null) {
            headers.append ("Accept-Ranges", "bytes");

            range += this.start.to_string () + "-" +
                     this.stop.to_string () + "/" +
                     this.total_length.to_string ();
            headers.append ("Content-Range", range);
        }

        headers.set_content_length (this.length);
    }
}
