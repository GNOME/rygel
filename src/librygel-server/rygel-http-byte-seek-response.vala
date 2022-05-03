/*
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Craig Pratt <craig@ecaspia.com>
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

using GUPnP;

public class Rygel.HTTPByteSeekResponse : Rygel.HTTPResponseElement {
    /**
     * The start of the range in bytes
     */
    public int64 start_byte { get; set; }

    /**
     * The end of the range in bytes (inclusive)
     */
    public int64 end_byte { get; set; }

    /**
     * The length of the range in bytes
     */
    public int64 range_length { get; private set; }

    /**
     * The length of the resource in bytes
     */
    public int64 total_size { get; set; }

    public HTTPByteSeekResponse (int64 start_byte,
                                 int64 end_byte,
                                 int64 total_size) {
        this.start_byte = start_byte;
        this.end_byte = end_byte;
        // +1, since range is inclusive
        this.range_length = end_byte - start_byte + 1;
        this.total_size = total_size;
    }

    public HTTPByteSeekResponse.from_request (HTTPByteSeekRequest request) {
        this.start_byte = request.start_byte;
        this.end_byte = request.end_byte;
        this.range_length = request.range_length;
        this.total_size = request.total_size;
    }

    public override void add_response_headers (Rygel.HTTPRequest request) {
        if (this.end_byte != -1) {
            // Content-Range: bytes START_BYTE-END_BYTE/TOTAL_LENGTH (or "*")
            request.msg.get_response_headers ().set_content_range (this.start_byte,
                                                            this.end_byte,
                                                            this.total_size);
            request.msg.get_response_headers ().append ("Accept-Ranges", "bytes");
            request.msg.get_response_headers ().set_content_length (this.range_length);
        }
    }

    public override string to_string () {
        return ("HTTPByteSeekResponse(bytes=%lld-%lld/%lld (%lld bytes))"
                .printf (this.start_byte,
                         this.end_byte,
                         this.total_size,
                         this.range_length));
    }
}
