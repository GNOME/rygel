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

/**
 * This class represents a DLNA TimeSeekRange request.
 *
 * A TimeSeekRange request can only have a time range ("npt=start-end").
 */
public class Rygel.HTTPTimeSeekRequest : Rygel.HTTPSeekRequest {
    public const string TIMESEEKRANGE_HEADER = "TimeSeekRange.dlna.org";
    /**
     * Requested range start time, in microseconds
     */
    public int64 start_time;

    /**
     * Requested range end time, in microseconds
     */
    public int64 end_time;

    /**
     * Requested range duration, in microseconds
     */
    public int64 range_duration;

    /**
     * The total duration of the resource, in microseconds
     */
    public int64 total_duration;

    /**
     * Create a HTTPTimeSeekRequest corresponding with a HTTPGet that contains a
     * TimeSeekRange.dlna.org header value.
     *
     * Note: This constructor will check the syntax of the request (per DLNA
     * 7.5.4.3.2.24.3) as well as perform some range validation. If the
     * provided request is associated with a handler that can provide content
     * duration, the start and end time will be checked for out-of-bounds
     * conditions. Additionally, the start and end will be checked according
     * to playspeed direction (with rate +1.0 assumed when speed is not
     * provided). When speed is provided, the range end parameter check is
     * relaxed when the rate is not +1.0 (per DLNA 7.5.4.3.2.24.4).
     *
     * @param request The HTTP GET/HEAD request
     * @param speed An associated speed request
     */
    internal HTTPTimeSeekRequest (Soup.ServerMessage message,
                                  HTTPGetHandler handler,
                                  PlaySpeed? speed)
                                  throws HTTPSeekRequestError {
        base ();

        bool positive_rate = (speed == null) || speed.is_positive ();
        bool trick_mode = (speed != null) && !speed.is_normal_rate ();

        this.total_duration = handler.get_resource_duration ();
        if (this.total_duration <= 0) {
            this.total_duration = UNSPECIFIED;
        }

        var range = message.get_request_headers ().get_one (TIMESEEKRANGE_HEADER);

        if (range == null) {
            throw new HTTPSeekRequestError.INVALID_RANGE ("%s not present",
                                                          TIMESEEKRANGE_HEADER);
        }

        if (!range.has_prefix ("npt=")) {
            throw new HTTPSeekRequestError.INVALID_RANGE
                          ("Invalid %s value (missing npt field): '%s'",
                          TIMESEEKRANGE_HEADER, range);
        }

        var parsed_range = range.substring (4);
        if (!parsed_range.contains ("-")) {
            throw new HTTPSeekRequestError.INVALID_RANGE
                          ("Invalid %s request with no '-': '%s'",
                          TIMESEEKRANGE_HEADER, range);
        }

        var range_tokens = parsed_range.split ("-", 2);

        int64 start = UNSPECIFIED;
        if (!parse_npt_time (range_tokens[0], ref start)) {
            throw new HTTPSeekRequestError.INVALID_RANGE
                          ("Invalid %s value (no start): '%s'",
                          TIMESEEKRANGE_HEADER, range);
        }

        // Check for out-of-bounds range start and clamp it in if in trick/scan mode
        if ((this.total_duration != UNSPECIFIED) && (start > this.total_duration)) {
            if (trick_mode && !positive_rate) { // Per DLNA 7.5.4.3.2.24.4
                this.start_time = this.total_duration;
            } else { // See DLNA 7.5.4.3.2.24.8
                var msg = /*_*/("Invalid %s start time %lldns is beyond the content duration of %lldns");

                throw new HTTPSeekRequestError.OUT_OF_RANGE
                                        (msg,
                                         TIMESEEKRANGE_HEADER,
                                         start,
                                         this.total_duration);
            }
        } else { // Nothing to check it against - just store it
            this.start_time = start;
        }

        // Look for an end time
        int64 end = UNSPECIFIED;
        if (parse_npt_time (range_tokens[1], ref end)) {
            // The end time was specified in the npt ("start-end")
            // Check for valid range
            if (positive_rate) {
                // Check for out-of-bounds range end or fence it in
                if ((this.total_duration != UNSPECIFIED) &&
                    (end > this.total_duration)) {
                    if (trick_mode) { // Per DLNA 7.5.4.3.2.24.4
                        this.end_time = this.total_duration;
                    } else { // Per DLNA 7.5.4.3.2.24.8
                        var msg = /*_*/("Invalid %s start time %lldns is beyond the content duration of %lldns");
                        throw new HTTPSeekRequestError.OUT_OF_RANGE
                                        (msg,
                                         TIMESEEKRANGE_HEADER,
                                         end,
                                         this.total_duration);
                    }
                } else {
                    this.end_time = end;
                }

                this.range_duration =  this.end_time - this.start_time;
                // At positive rate, start < end
                if (this.range_duration <= 0) { // See DLNA 7.5.4.3.2.24.12
                    var msg = /*_*/("Invalid %s value (start time after end time - forward scan): '%s'");
                    throw new HTTPSeekRequestError.INVALID_RANGE
                                        (msg,
                                         TIMESEEKRANGE_HEADER,
                                         range);
                }
            } else { // Negative rate
                // Note: start_time has already been checked/clamped
                this.end_time = end;
                this.range_duration = this.start_time - this.end_time;
                // At negative rate, start > end
                if (this.range_duration <= 0) { // See DLNA 7.5.4.3.2.24.12
                    var msg = ("Invalid %s value (start time before end time - reverse scan): '%s'");
                    throw new HTTPSeekRequestError.INVALID_RANGE
                                        (msg,
                                         TIMESEEKRANGE_HEADER,
                                         range);
                }
            }
        } else { // End time not specified in the npt field ("start-")
            // See DLNA 7.5.4.3.2.24.4
            this.end_time = UNSPECIFIED; // Will indicate "end/beginning of binary"
            if (this.total_duration == UNSPECIFIED) {
                this.range_duration = UNSPECIFIED;
            } else {
                if (positive_rate) {
                    this.end_time = this.total_duration - TimeSpan.MILLISECOND;
                    this.range_duration = this.total_duration - this.start_time;
                } else {
                    this.end_time = 0;
                    // Going backward from start to 0
                    this.range_duration = this.start_time;
                }
            }
        }
    }

    public string to_string () {
        return ("HTTPTimeSeekRequest (npt=%lld-%s)".printf
                                        (this.start_time,
                                         (this.end_time != UNSPECIFIED
                                          ? this.end_time.to_string()
                                          : "*")));
    }

    /**
     * Return true if time-seek is supported.
     *
     * This method utilizes elements associated with the request to determine if
     * a TimeSeekRange request is supported for the given request/resource.
     */
    public static bool supported (Soup.ServerMessage message,
                                  HTTPGetHandler handler) {
        bool force_seek = false;

        try {
            var hack = ClientHacks.create (message);
            force_seek = hack.force_seek ();
        } catch (Error error) { /* Exception means no hack needed */ }

        return force_seek || handler.supports_time_seek ();
    }

    /**
     * Return true of the HTTPGet contains a TimeSeekRange request.
     */
    public static bool requested (Soup.ServerMessage message) {
        var header = message.get_request_headers ().get_one (TIMESEEKRANGE_HEADER);

        return (header != null);
    }

    // Parses npt times in the format of '417.33' and returns the time in
    // microseconds
    private static bool parse_npt_seconds (string range_token,
                                           ref int64 value) {
        if (range_token[0].isdigit ()) {
            value = (int64) (double.parse (range_token) * TimeSpan.SECOND);
        } else {
            return false;
        }

        return true;
    }

    // Parses npt times in the format of '10:19:25.7' and returns the time in
    // microseconds
    private static bool parse_npt_time (string? range_token,
                                        ref int64 value) {
        if (range_token == null) {
            return false;
        }

        if (range_token.index_of (":") == -1) {
            return parse_npt_seconds (range_token, ref value);
        }
        // parse_seconds has a ':' in it...
        int64 seconds_sum = 0;
        int time_factor = 0;
        string[] time_tokens;

        seconds_sum = 0;
        time_factor = 3600;

        time_tokens = range_token.split (":", 3);
        if (time_tokens[0] == null ||
            time_tokens[1] == null ||
            time_tokens[2] == null) {
            return false;
        }

        foreach (string time in time_tokens) {
            if (time[0].isdigit ()) {
                seconds_sum += (int64) ((double.parse (time) *
                                         TimeSpan.SECOND) * time_factor);
            } else {
                return false;
            }
            time_factor /= 60;
        }
        value = seconds_sum;

        return true;
    }
}
