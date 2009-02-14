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
 * Represents Tracker Music category.
 */
public class Rygel.TrackerMusicContainer : Rygel.TrackerContainer {
    public TrackerMusicContainer (string id,
                                  string parent_id,
                                  string title) {
        base (id, parent_id, title, "Music", MediaItem.MUSIC_CLASS);
    }

    protected override string[] get_metadata_keys () {
        return TrackerMusicItem.get_metadata_keys ();
    }

    protected override MediaItem? fetch_item_by_path (string   path,
                                                      string[] metadata)
                                                      throws GLib.Error {
        return new TrackerMusicItem (this.id + ":" + path,
                                     path,
                                     this,
                                     metadata);
    }
}

