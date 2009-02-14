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

using Rygel;

/**
 * Represents Tracker Video category.
 */
public class Rygel.TrackerVideoContainer : Rygel.TrackerContainer {
    public TrackerVideoContainer (string id,
                                  string parent_id,
                                  string title) {
        base (id, parent_id, title, "Videos", MediaItem.VIDEO_CLASS);
    }

    protected override MediaItem? fetch_item_by_path (string path)
                                                      throws GLib.Error {
        string[] keys = TrackerVideoItem.get_metadata_keys ();

        /* TODO: make this async */
        string[] item_metadata = this.metadata.Get (this.category, path, keys);

        return new TrackerVideoItem (this.id + ":" + path,
                                     path,
                                     this,
                                     item_metadata);
    }
}

