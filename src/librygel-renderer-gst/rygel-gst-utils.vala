/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Gst;

internal errordomain Rygel.GstError {
    MISSING_PLUGIN,
    LINK
}

internal abstract class Rygel.GstUtils {
    public static ClockTime time_from_string (string str) {
        uint64 hours, minutes, seconds;

        str.scanf ("%llu:%2llu:%2llu%*s", out hours, out minutes, out seconds);

        return (ClockTime) ((hours * 3600 + minutes * 60 + seconds) *
                            Gst.SECOND);
    }

    public static string time_to_string (ClockTime time) {
        uint64 hours, minutes, seconds;

        hours   = time / Gst.SECOND / 3600;
        seconds = time / Gst.SECOND % 3600;
        minutes = seconds / 60;
        seconds = seconds % 60;

        return "%llu:%.2llu:%.2llu".printf (hours, minutes, seconds);
    }
}
