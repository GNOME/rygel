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

internal abstract class Rygel.TimeUtils {
    public static int64 time_from_string (string str) {
        uint64 hours, minutes, seconds, msecs;
        string time_str = str;
        int sign = 1;

        switch (str[0]) {
            case '-':
                sign = -1;
                time_str = str.substring (1);

                break;
            case '+':
                time_str = str.substring (1);

                break;
            default:
                break;
        }

        time_str.scanf ("%llu:%2llu:%2llu.%3llu",
                        out hours,
                        out minutes,
                        out seconds,
                        out msecs);

        return sign * ((int64)(hours * 3600 + minutes * 60 + seconds) *
               TimeSpan.SECOND + (int64)msecs * TimeSpan.MILLISECOND);
    }

    public static string time_to_string (int64 time) {
        uint64 hours, minutes, seconds, totsecs, msecs;
        string sign = "";

        if (time < 0) {
            sign = "-";
            time = -time;
        };

        hours   = time / TimeSpan.SECOND / 3600;
        seconds = time / TimeSpan.SECOND % 3600;
        minutes = seconds / 60;
        seconds = seconds % 60;

        totsecs = (hours * 3600 + minutes * 60 + seconds) * TimeSpan.SECOND;
        msecs = (time - totsecs) / TimeSpan.MILLISECOND;

        return "%s%llu:%.2llu:%.2llu.%.3llu".printf (sign, hours, minutes,
                                                     seconds, msecs);
    }
}
