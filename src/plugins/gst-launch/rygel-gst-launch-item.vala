/*
 * Copyright (C) 2009 Thijs Vermeir <thijsvermeir@gmail.com>
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
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

using Rygel;
using GUPnP;
using Gee;
using Gst;

/**
 * Represents Test audio item.
 */
public class Rygel.GstLaunch.Item : Rygel.MediaItem {
    string launch_line;

    public Item (string         id,
                 MediaContainer parent,
                 string         title,
                 string         mime_type,
                 string         launch_line) {
        string upnp_class;

        if (mime_type.has_prefix ("audio")) {
             upnp_class = MediaItem.AUDIO_CLASS;
        } else {
             upnp_class = MediaItem.VIDEO_CLASS;
        }

        base (id, parent, title, upnp_class);

        this.mime_type = mime_type;
        this.launch_line = launch_line;
    }

    public override Element? create_stream_source () {
        try {
          return Gst.parse_bin_from_description (this.launch_line, true);
        } catch (Error err) {
          warning ("parse launchline failed: %s", err.message);
          return null;
        }
    }
}

