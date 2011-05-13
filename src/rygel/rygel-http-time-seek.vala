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

using Gst;

internal class Rygel.HTTPTimeSeek : Rygel.HTTPSeek {
    public HTTPTimeSeek (HTTPGet request) throws HTTPSeekError {
        string range;
        string[] range_tokens;
        int64 start = 0;
        int64 duration = (request.item as AudioItem).duration * SECOND;
        int64 stop = duration - MSECOND;

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

            if (range_tokens[0].index_of (":") == -1) {
                if (!parse_seconds (range_tokens, ref start, ref stop)) {
                    throw new HTTPSeekError.INVALID_RANGE
                                        (_("Invalid Range '%s'"),
                                           range);
                }
            } else {
                if (!parse_time (range_tokens,
                                 ref start,
                                 ref stop)) {
                    throw new HTTPSeekError.INVALID_RANGE
                                        (_("Invalid Range '%s'"),
                                           range);
                }
            }
        }

        base (request.msg, start, stop, MSECOND, duration);
    }

    public static bool needed (HTTPGet request) {
        return request.item is AudioItem &&
               (request.item as AudioItem).duration > 0 &&
               (request.handler is HTTPTranscodeHandler ||
                (request.thumbnail == null &&
                 request.subtitle == null &&
                 request.item.is_live_stream ()));
    }

    public static bool requested (HTTPGet request) {
        return request.msg.request_headers.get_one ("TimeSeekRange.dlna.org") !=
               null;
    }

    public override void add_response_headers () {
        // TimeSeekRange.dlna.org: npt=START_TIME-END_TIME/DURATION
        double start = (double) this.start / SECOND;
        double stop = (double) this.stop / SECOND;
        double total = (double) this.total_length / SECOND;

        var start_str = new char[double.DTOSTR_BUF_SIZE];
        var stop_str = new char[double.DTOSTR_BUF_SIZE];
        var total_str = new char[double.DTOSTR_BUF_SIZE];

        var range = "npt=" + start.format (start_str, "%.3f") + "-" +
                             stop.format (stop_str, "%.3f") + "/" +
                             total.format (total_str, "%.3f");

        this.msg.response_headers.append ("TimeSeekRange.dlna.org", range);
    }

    // Parses TimeSeekRanges in the format of '417.33-779.09'
    private static bool parse_seconds (string[]  range_tokens,
                                       ref int64 start,
                                       ref int64 stop) {
        string time;

        // Get start time
        time = range_tokens[0];
        if (time[0].isdigit ()) {
            start = (int64) (double.parse (time) * SECOND);
        } else {
            return false;
        }

        // Get end time
        time = range_tokens[1];
        if (time[0].isdigit ()) {
            stop = (int64) (double.parse (time) * SECOND);
            if (stop < start) {
                return false;
            }
        } else if (time != "") {
            return false;
        }

        return true;
    }

    // Parses TimeSeekRanges in the format of '10:19:25.7-13:23:33.6'
    private static bool parse_time (string[]  range_tokens,
                                    ref int64 start,
                                    ref int64 stop ) {
        int64 seconds_sum = 0;
        int time_factor = 0;
        bool parsing_start = true;
        string[] time_tokens;

        foreach (string range_token in range_tokens) {
            if (range_token == "") {
                continue;
            }
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
                                             SECOND) * time_factor);
                } else {
                    return false;
                }
                time_factor /= 60;
            }

            if (parsing_start) {
                start = seconds_sum;
                parsing_start = false;
            } else {
                stop = seconds_sum;
            }
        }

        if (start > stop) {
            return false;
        }

        return true;
    }
}
