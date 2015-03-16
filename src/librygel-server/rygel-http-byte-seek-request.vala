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

using GUPnP;

public class Rygel.HTTPByteSeekRequest : Rygel.HTTPSeekRequest {
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


    public HTTPByteSeekRequest (HTTPGet request) throws HTTPSeekRequestError,
                                                 HTTPRequestError {
        base ();
        unowned string range = request.msg.request_headers.get_one ("Range");
        if (range == null) {
            throw new HTTPSeekRequestError.INVALID_RANGE ("Range header not present");
        }

        int64 start_byte, end_byte, total_size;

        // The size (entity body size) may not be known up-front (especially
        // for live sources)
        total_size = request.handler.get_resource_size ();
        if (total_size < 0) {
            total_size = UNSPECIFIED;
        }

        // Note: DLNA restricts the syntax on the Range header (see
        //       DLNA 7.5.4.3.2.22.3) And we need to retain the concept of an
        //       "open range" ("bytes=DIGITS-") since the interpretation and
        //       legality varies based on the context (e.g. DLNA 7.5.4.3.2.19.2,
        //       7.5.4.3.2.20.1, 7.5.4.3.2.20.3)
        if (!range.has_prefix ("bytes=")) {
            var msg = ("Invalid Range value (missing 'bytes=' field): '%s'");
            throw new HTTPSeekRequestError.INVALID_RANGE (msg, range);
        }

        var parsed_range = range.substring (6);
        if (!parsed_range.contains ("-")) {
            throw new HTTPSeekRequestError.INVALID_RANGE
                          ("Invalid Range request with no '-': '%s'", range);
        }

        var range_tokens = parsed_range.split ("-", 2);

        if (!int64.try_parse (strip_leading_zeros (range_tokens[0]),
                              out start_byte)) {
            throw new HTTPSeekRequestError.INVALID_RANGE
                          ("Invalid Range start value: '%s'", range);
        }

        if ((total_size != UNSPECIFIED) && (start_byte >= total_size)) {
            var msg = /*_*/("Range start value %lld is larger than content size %lld: '%s'");
            throw new HTTPSeekRequestError.OUT_OF_RANGE (msg,
                                                         start_byte,
                                                         total_size,
                                                         range);
        }

        if (range_tokens[1] == null || (range_tokens[1].length == 0)) {
            end_byte = total_size;
            if (total_size != UNSPECIFIED) {
                range_length = end_byte - start_byte + 1; // range is inclusive
            } else {
                range_length = UNSPECIFIED;
            }
        } else {
            if (!int64.try_parse (strip_leading_zeros(range_tokens[1]),
                                  out end_byte)) {
                throw new HTTPSeekRequestError.INVALID_RANGE
                                       ("Invalid Range end value: '%s'", range);
            }
            if (end_byte < start_byte) {
                var msg = /*_*/("Range end value %lld is smaller than range start value %lld: '%s'");
                throw new HTTPSeekRequestError.INVALID_RANGE (msg,
                                                              end_byte,
                                                              start_byte,
                                                              range);
            }
            if ((total_size != UNSPECIFIED) && (end_byte >= total_size)) {
                end_byte = total_size - 1;
            }
            range_length = end_byte - start_byte + 1; // range is inclusive
        }
        this.start_byte = start_byte;
        this.end_byte = end_byte;
        this.total_size = total_size;
    }

    public static bool supported (HTTPGet request) {
        bool force_seek = false;

        try {
            var hack = ClientHacks.create (request.msg);
            force_seek = hack.force_seek ();
        } catch (Error error) { }

        return force_seek || request.handler.supports_byte_seek ();
    }

    public static bool requested (HTTPGet request) {
        return (request.msg.request_headers.get_one ("Range") != null);
    }

    // Leading "0"s cause try_parse() to assume the value is octal (see Vala
    // bug 656691) So we strip them off before passing to int64.try_parse()
    private static string strip_leading_zeros (string number_string) {
        int i=0;
        while ((number_string[i] == '0') && (i < number_string.length)) {
            i++;
        }
        if (i == 0) {
            return number_string;
        } else {
            return number_string[i:number_string.length];
        }
    }

}
