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
    // FIXME: We are only accepting time range in this format:
    //
    // TimeSeekRange.dlna.org : npt=417.33-779.09
    //
    // and not
    //
    // TimeSeekRange.dlna.org : npt=10:19:25.7-13:23:33.6
    public HTTPTimeSeek (HTTPGet request) throws HTTPSeekError {
        string range, time;
        string[] range_tokens;
        int64 start = 0;
        int64 duration = (request.item as AudioItem).duration * SECOND;
        int64 stop = duration - SECOND;

        range = request.msg.request_headers.get_one ("TimeSeekRange.dlna.org");
        if (range != null) {
            if (!range.has_prefix ("npt=")) {
                throw new HTTPSeekError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            range_tokens = range.substring (4).split ("-", 2);
            if (range_tokens[0] == null || range_tokens[1] == null) {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            // Get start time
            time = range_tokens[0];
            if (time[0].isdigit ()) {
                start = (int64) (double.parse (time) * SECOND);
            } else if (time != "") {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }

            // Get end time
            time = range_tokens[1];
            if (time[0].isdigit()) {
                stop = (int64) (double.parse (time) * SECOND);
                if (stop < start) {
                    throw new HTTPSeekError.INVALID_RANGE
                                        (_("Invalid Range '%s'"), range);
                }
            } else if (time != "") {
                throw new HTTPSeekError.INVALID_RANGE (_("Invalid Range '%s'"),
                                                       range);
            }
        }

        base (request.msg, start, stop, duration);
    }

    public static bool needed (HTTPGet request) {
        return request.item is AudioItem &&
               (request.item as AudioItem).duration > 0 &&
               (request.handler is HTTPTranscodeHandler ||
                (request.thumbnail == null &&
                 request.subtitle == null &&
                 request.item.should_stream ()));
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

        var range = "npt=" + start.format (start_str, "%.2f") + "-" +
                             stop.format (stop_str, "%.2f") + "/" +
                             total.format (total_str, "%.2f");

        this.msg.response_headers.append ("TimeSeekRange.dlna.org", range);
    }
}
