/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

/**
 * Represents MediaExport item.
 */
public class Rygel.MediaExportItem : MediaItem {
    public MediaExportItem (MediaContainer parent,
                            File           file,
                            FileInfo       info) {
        string content_type = info.get_content_type ();
        string item_class = null;
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 info.get_name ());

        // use heuristics based on content type; will use MediaHarvester
        // when it's ready

        if (content_type.has_prefix ("video/")) {
            item_class = MediaItem.VIDEO_CLASS;
        } else if (content_type.has_prefix ("audio/")) {
            item_class = MediaItem.AUDIO_CLASS;
        } else if (content_type.has_prefix ("image/")) {
            item_class = MediaItem.IMAGE_CLASS;
        }

        if (item_class == null) {
            item_class = MediaItem.AUDIO_CLASS;
            warning ("Failed to detect UPnP class for '%s', assuming it's '%s'",
                     file.get_uri (), item_class);
        }

        base (id, parent, info.get_name (), item_class);

        this.mime_type = content_type;
        this.uris.add (file.get_uri ());
    }
}

