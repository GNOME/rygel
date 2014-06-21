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

internal class Rygel.HTTPTimeSeek : Rygel.HTTPSeek {
    public HTTPTimeSeek (HTTPGet request) throws HTTPSeekError {
        string range;
        string[] range_tokens;
        int64 start = 0;
        int64 duration = (request.object as AudioItem).duration * TimeSpan.SECOND;
        int64 stop = duration - TimeSpan.MILLISECOND;
        int64 parsed_value = 0;
        bool parsing_start = true;

        range = request.msg.request_headers.get_one ("TimeSeekRange.dlna.org");

        if (range != null) {
            if (!range.has_prefix ("npt=")) {
                throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            range_tokens = range.substring (4).split ("-", 2);
            if (range_tokens[0] == null ||
                // Start token of the range must be provided
                range_tokens[0] == "" ||
                range_tokens[1] == null) {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            foreach (string range_token in range_tokens) {
                if (range_token == "") {
                    continue;
                }

                if (range_token.index_of (":") == -1) {
                    if (!parse_seconds (range_token, ref parsed_value)) {
                        throw new HTTPSeekError.INVALID_RANGE
                                            (_("Invalid Range '%s'"),
                                               range);
                    }
                } else {
                    if (!parse_time (range_token,
                                     ref parsed_value)) {
                        throw new HTTPSeekError.INVALID_RANGE
                                            (_("Invalid Range '%s'"),
                                               range);
                    }
                }

                if (parsing_start) {
                    parsing_start = false;
                    start = parsed_value;
                } else {
                    stop = parsed_value;
                }
            }

            if (start > stop) {
                throw new HTTPSeekError.INVALID_RANGE
                                    (_("Invalid Range '%s'"),
                                       range);
            }
        }

        base (request.msg, start, stop - 1, TimeSpan.MILLISECOND, duration);
        this.seek_type = HTTPSeekType.TIME;
    }

    public static bool needed (HTTPGet request) {
        bool force_seek = false;

        try {
            var hack = ClientHacks.create (request.msg);
            force_seek = hack.force_seek ();
        } catch (Error error) { }

        return force_seek || (request.object is AudioItem &&
               (request.object as AudioItem).duration > 0 &&
               (request.handler is HTTPTranscodeHandler ||
                (request.thumbnail == null &&
                 request.subtitle == null &&
                 (request.object as MediaFileItem).is_live_stream ())));
    }

    public static bool requested (HTTPGet request) {
        return request.msg.request_headers.get_one ("TimeSeekRange.dlna.org") !=
               null;
    }

    public override void add_response_headers () {
        // TimeSeekRange.dlna.org: npt=START_TIME-END_TIME/DURATION
        double start = (double) this.start / TimeSpan.SECOND;
        double stop = (double) this.stop / TimeSpan.SECOND;
        double total = (double) this.total_length / TimeSpan.SECOND;

        var start_str = new char[double.DTOSTR_BUF_SIZE];
        var stop_str = new char[double.DTOSTR_BUF_SIZE];
        var total_str = new char[double.DTOSTR_BUF_SIZE];

        var range = "npt=" + start.format (start_str, "%.3f") + "-" +
                             stop.format (stop_str, "%.3f") + "/" +
                             total.format (total_str, "%.3f");

        this.msg.response_headers.append ("TimeSeekRange.dlna.org", range);
    }

    // Parses npt times in the format of '417.33'
    private static bool parse_seconds (string    range_token,
                                       ref int64 value) {
        if (range_token[0].isdigit ()) {
            value = (int64) (double.parse (range_token) * TimeSpan.SECOND);
        } else {
            return false;
        }
        return true;
    }

    // Parses npt times in the format of '10:19:25.7'
    private static bool parse_time (string    range_token,
                                    ref int64 value) {
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
