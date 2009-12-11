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
using Gee;

/**
 * Tracker video item factory.
 */
public class Rygel.TrackerVideoItemFactory : Rygel.TrackerItemFactory {
    private enum VideoMetadata {
        HEIGHT = Metadata.LAST_KEY,
        WIDTH,
        DURATION,

        LAST_KEY
    }

    private const string CATEGORY = "nmm:Video";

    public TrackerVideoItemFactory () {
        base (CATEGORY, MediaItem.VIDEO_CLASS);
    }

    public override MediaItem create (string                 id,
                                      string                 uri,
                                      TrackerSearchContainer parent,
                                      string[]               metadata)
                                      throws GLib.Error {
        var item = base.create (id, uri, parent, metadata);

        if (metadata[VideoMetadata.WIDTH] != "")
            item.width = metadata[VideoMetadata.WIDTH].to_int ();

        if (metadata[VideoMetadata.HEIGHT] != "")
            item.height = metadata[VideoMetadata.HEIGHT].to_int ();

        if (metadata[VideoMetadata.DURATION] != "")
            item.duration = metadata[VideoMetadata.DURATION].to_int ();

        return item;
    }

    public override ArrayList<string> get_metadata_keys () {
        var keys = base.get_metadata_keys ();

        keys.add ("nfo:width");  // VideoMetadata.WIDTH
        keys.add ("nfo:height"); // VideoMetadata.HEIGHT
        keys.add ("nmm:length"); // VideoMetadata.DURATION

        assert (keys.size == VideoMetadata.LAST_KEY);

        return keys;
    }
}

