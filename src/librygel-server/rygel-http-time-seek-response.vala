/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
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

public class Rygel.HTTPTimeSeekResponse : Rygel.HTTPResponseElement {
    /**
     * Effective range start time, in microseconds
     */
    public int64 start_time { get; private set; }

    /**
     * Effective range end time, in microseconds
     */
    public int64 end_time { get; private set; }

    /**
     * Effective range duration, in microseconds
     */
    public int64 range_duration { get; private set; }

    /**
     * The total duration of the resource, in microseconds
     */
    public int64 total_duration { get; private set; }

    /**
     * The start of the range in bytes
     */
    public int64 start_byte { get; private set; }

    /**
     * The end of the range in bytes (inclusive)
     */
    public int64 end_byte { get; private set; }

    /**
     * The response length in bytes
     */
    public int64 response_length { get; private set; }

    /**
     * The length of the resource in bytes
     */
    public int64 total_size { get; private set; }

    /**
     * Construct a HTTPTimeSeekResponse with time and byte range
     *
     * start_time and start_byte must be specified.
     *
     * if total_duration and total_size are UNSPECIFIED, then the content
     * duration/size will be signaled as unknown ("*")
     *
     * if end_time is UNSPECIFIED, then the time range end will be omitted
     * from the response. If the end_byte is UNSPECIFIED, the entire byte
     * range response will be omitted. (see DLNA 7.5.4.3.2.24.3)
     */
    public HTTPTimeSeekResponse (int64 start_time,
                                 int64 end_time,
                                 int64 total_duration,
                                 int64 start_byte,
                                 int64 end_byte,
                                 int64 total_size) {
        base ();
        this.start_time = start_time;
        this.end_time = end_time;
        this.total_duration = total_duration;

        this.start_byte = start_byte;
        this.end_byte = end_byte;
        this.response_length = end_byte;

        if (this.response_length != UNSPECIFIED) {
            this.response_length -= (start_byte - 1);
        }

        this.total_size = total_size;
    }

    /**
     * Create a HTTPTimeSeekResponse only containing a time range
     *
     * Note: This form is only valid when byte-seek is not supported,
     * according to the associated resource's ProtocolInfo (see DLNA
     * 7.5.4.3.2.24.5)
     */
    public HTTPTimeSeekResponse.time_only (int64 start_time,
                                           int64 end_time,
                                           int64 total_duration) {
        base ();
        this.start_time = start_time;
        this.end_time = end_time;
        this.total_duration = total_duration;

        this.start_byte = UNSPECIFIED;
        this.end_byte = UNSPECIFIED;
        this.response_length = UNSPECIFIED;
        this.total_size = UNSPECIFIED;
    }

    /**
     * Construct a HTTPTimeSeekResponse with time and byte range and allowing
     * for a response length override. This is useful when the response body
     * is larger than the specified byte range from the original content
     * binary.
     *
     * start_time and start_byte must be specified.
     *
     * If total_duration and total_size are UNSPECIFIED, then the content
     * duration/size will be signaled as unknown ("*")
     *
     * if end_time is UNSPECIFIED, then the time range end will be omitted
     * from the response. If the end_byte is UNSPECIFIED, the entire byte
     * range response will be omitted. (see DLNA 7.5.4.3.2.24.3)
     */
    public HTTPTimeSeekResponse.with_length (int64 start_time,
                                             int64 end_time,
                                             int64 total_duration,
                                             int64 start_byte,
                                             int64 end_byte,
                                             int64 total_size,
                                             int64 response_length) {
        base ();
        this.start_time = start_time;
        this.end_time = end_time;
        this.total_duration = total_duration;

        this.start_byte = start_byte;
        this.end_byte = end_byte;
        this.response_length = response_length;
        this.total_size = total_size;
    }

    /**
     * Create a HTTPTimeSeekResponse from a HTTPTimeSeekRequest
     *
     * Note: This form is only valid when byte-seek is not supported,
     * according to the associated resource's ProtocolInfo (see DLNA
     * 7.5.4.3.2.24.5)
     */
    public HTTPTimeSeekResponse.from_request
                                        (HTTPTimeSeekRequest time_seek_request,
                                         int64               total_duration ) {
        this.time_only (time_seek_request.start_time,
                        time_seek_request.end_time,
                        total_duration);
    }

    public override void add_response_headers (Rygel.HTTPRequest request) {
        var response = get_response_string ();
        if (response != null) {
            var headers = request.msg.get_response_headers ();
            headers.append (HTTPTimeSeekRequest.TIMESEEKRANGE_HEADER, response);
            if (this.response_length != UNSPECIFIED) {
                // Note: Don't use set_content_range () here - we don't want a
                // "Content-range" header
                headers.set_content_length (this.response_length);
            }

            if (request.msg.get_http_version () == Soup.HTTPVersion.@1_0) {
                headers.replace ("Pragma", "no-cache");
            }
        }
    }

    private string? get_response_string () {
        if (start_time == UNSPECIFIED) {
            return null;
        }

        // The response form of TimeSeekRange:
        //
        // TimeSeekRange.dlna.org: npt=START_TIME-END_TIME/DURATION
        // bytes=START_BYTE-END_BYTE/LENGTH
        //
        // The "bytes=" field can be ommitted in some cases. (e.g. ORG_OP
        // a-val==1, b-val==0) The DURATION can be "*" in some cases (e.g. for
        // limited-operation mode) The LENGTH can be "*" in some cases (e.g.
        // for limited-operation mode) And the entire response header can be
        // ommitted for HEAD requests (see DLNA 7.5.4.3.2.24.2)

        // It's not our job at this level to enforce all the semantics of the
        // TimeSeekRange response, as we don't have enough context. Setting up
        // the correct HTTPTimeSeekRequest object is the responsibility of the
        // object owner. To form the response, we just use what is set.

        var response = new StringBuilder ();
        var locale = Intl.setlocale (LocaleCategory.NUMERIC, "C");
        response.append ("npt=");
        response.append_printf ("%.3f-",
                                (double) this.start_time / TimeSpan.SECOND);
        if (this.end_time != UNSPECIFIED) {
            response.append_printf ("%.3f",
                                    (double) this.end_time / TimeSpan.SECOND);
        }
        if (this.total_duration != UNSPECIFIED) {
            var total = (double) this.total_duration / TimeSpan.SECOND;
            response.append_printf ("/%.3f", total);
        } else {
            response.append ("/*");
        }
        Intl.setlocale (LocaleCategory.NUMERIC, locale);

        if ((this.start_byte != UNSPECIFIED) &&
            (this.end_byte != UNSPECIFIED)) {
            response.append (" bytes=");
            response.append (this.start_byte.to_string ());
            response.append ("-");
            response.append (this.end_byte.to_string ());
            response.append ("/");
            if (this.total_size != UNSPECIFIED) {
                response.append (this.total_size.to_string ());
            } else {
                response.append ("*");
            }
        }

        return response.str;
   }

    public override string to_string () {
        return ("HTTPTimeSeekResponse (%s)".printf
                                        (this.get_response_string ()));
    }
}
