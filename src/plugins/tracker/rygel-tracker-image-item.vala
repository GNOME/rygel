/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
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
using DBus;

/**
 * Represents Tracker image item.
 */
public class Rygel.TrackerImageItem : Rygel.TrackerItem {
    public const string SERVICE = "Images";

    public TrackerImageItem (string                 id,
                             string                 path,
                             TrackerSearchContainer parent,
                             string[]               metadata)
                             throws GLib.Error {
        base (id, path, parent, MediaItem.IMAGE_CLASS, metadata);

        if (metadata[Metadata.IMAGE_TITLE] != "")
            this.title = metadata[Metadata.IMAGE_TITLE];
        else
            /* If title wasn't provided, use filename instead */
            this.title = metadata[Metadata.FILE_NAME];

        if (metadata[Metadata.IMAGE_WIDTH] != "")
            this.width = metadata[Metadata.IMAGE_WIDTH].to_int ();

        if (metadata[Metadata.IMAGE_HEIGHT] != "")
            this.height = metadata[Metadata.IMAGE_HEIGHT].to_int ();

        if (metadata[Metadata.IMAGE_DATE] != "") {
            this.date = seconds_to_iso8601 (metadata[Metadata.IMAGE_DATE]);
        }

        this.author = metadata[Metadata.CREATOR];
        this.album = metadata[Metadata.IMAGE_ALBUM];
    }
}

