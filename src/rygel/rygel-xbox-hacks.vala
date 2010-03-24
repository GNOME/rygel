/*
 * Copyright (C) 2010 Nokia Corporation.
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

using Soup;

internal errordomain Rygel.XBoxHacksError {
    NA
}

internal class Rygel.XBoxHacks : GLib.Object {
    public XBoxHacks (Message msg) throws XBoxHacksError {
        if (!msg.request_headers.get ("User-Agent").contains ("XBox")) {
            throw new XBoxHacksError.NA ("Not Applicable");
        }
    }

    public void translate_container_id (ref string container_id) {
        if (container_id == "1" ||
            container_id == "4" ||
            container_id == "5" ||
            container_id == "6" ||
            container_id == "7") {
            container_id = "0";
        }
    }

    public void apply (MediaItem item) {
        if (item.mime_type == "video/x-msvideo") {
            item.mime_type = "video/avi";
        } else if (item.mime_type == "video/mpeg") {
            // Force transcoding for MPEG files
            item.mime_type = "invalid/content";
        }
    }
}
