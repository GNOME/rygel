/*
 * Copyright (C) 2014  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
 *
 * Author: Craig Pratt <craig@ecaspia.com>
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

public class Rygel.DLNAAvailableSeekRangeResponse : Rygel.HTTPResponseElement {
    public const string AVAILABLE_SEEK_RANGE_HEADER = "availableSeekRange.dlna.org";
    /**
     * The Limited Operation mode (0 or 1)
     */
    public int mode { get; private set; }

    /**
     * Available range start time, in microseconds
     */
    public int64 start_time { get; private set; }

    /**
     * Available range end time, in microseconds
     */
    public int64 end_time { get; private set; }

    /**
     * The start of the available range in bytes
     */
    public int64 start_byte { get; private set; }

    /**
     * The end of the available range in bytes (inclusive)
     */
    public int64 end_byte { get; private set; }

    /**
     * The length of the available range in bytes
     */
    public int64 range_length { get; private set; }

    public DLNAAvailableSeekRangeResponse (int mode,
                                           int64 start_time,
                                           int64 end_time,
                                           int64 start_byte,
                                           int64 end_byte) {
        base ();
        this.mode = mode;
        this.start_time = start_time;
        this.end_time = end_time;
        this.start_byte = start_byte;
        this.end_byte = end_byte;
        this.range_length = end_byte - start_byte + 1;
    }

    public DLNAAvailableSeekRangeResponse.time_only (int mode,
                                                     int64 start_time,
                                                     int64 end_time) {
        base ();
        this.mode = mode;
        this.start_time = start_time;
        this.end_time = end_time;
        this.start_byte = this.end_byte = this.range_length = UNSPECIFIED;
    }

    public override void add_response_headers (Rygel.HTTPRequest request) {
        var response = this.get_response_string ();
        if (response != null) {
            request.msg.get_response_headers ().append (AVAILABLE_SEEK_RANGE_HEADER,
                                                        response);
        }
    }

    private string? get_response_string () {
        if (start_time == UNSPECIFIED) {
            return null;
        }

        // The availableSeekRange format:
        //
        // availableSeekRange.dlna.org:
        // MODE npt=START_TIME-END_TIME bytes=START_BYTE-END_BYTE
        //
        // The MODE can be either "0" or "1", indicating the limited operation
        // mode being used by the server.
        //
        // The "bytes=" field can be ommitted in some cases. (e.g. ORG_OP
        // b-val==0 and lop-bytes is 0).

        // It's not our job at this level to enforce all the semantics of the
        // availableSeekRange response, as we don't have enough context.
        // Setting up the correct HTTPTimeSeekRequest object is the
        // responsibility of the object owner. To form the response, we just
        // use what is set.

        var response = new StringBuilder ();
        response.append (mode.to_string ());
        response.append (" npt=");
        response.append_printf ("%.3f-",
                                (double) this.start_time / TimeSpan.SECOND);
        response.append_printf ("%.3f",
                                (double) this.end_time / TimeSpan.SECOND);

        if (this.start_byte != UNSPECIFIED) {
            response.append (" bytes=");
            response.append (this.start_byte.to_string ());
            response.append ("-");
            response.append (this.end_byte.to_string ());
        }

        return response.str;
   }

    public override string to_string () {
        return ("HTTPTimeSeekResponse (%s)".printf
                                        (this.get_response_string ()));
    }
}
