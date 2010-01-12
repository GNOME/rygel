/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation.
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

using GUPnP;
using Gee;
using Gst;

/**
 * Represents Test video item.
 */
public class Rygel.TestVideoItem : Rygel.TestItem {
    private const string TEST_MIMETYPE = "video/mpeg";
    private const string PIPELINE = "videotestsrc is-live=1 ! " +
                                    "ffenc_mpeg2video ! " +
                                    "mpegtsmux";

    public TestVideoItem (string         id,
                          MediaContainer parent,
                          string         title) {
        base (id,
              parent,
              title,
              TEST_MIMETYPE,
              MediaItem.VIDEO_CLASS);
    }

    public override Element? create_stream_source () {
        try {
            return Gst.parse_bin_from_description (PIPELINE, true);
        } catch (Error err) {
            warning ("Required plugin missing (%s)", err.message);

            return null;
        }
    }
}

