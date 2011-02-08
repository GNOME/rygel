/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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

using Gee;

/**
 * Tracker video item factory.
 */
public class Rygel.Tracker.VideoItemFactory : ItemFactory {
    private enum VideoMetadata {
        HEIGHT = Metadata.LAST_KEY,
        WIDTH,
        DURATION,

        LAST_KEY
    }

    private const string CATEGORY = "nmm:Video";

    public VideoItemFactory () {
        base (CATEGORY,
              VideoItem.UPNP_CLASS,
              Environment.get_user_special_dir (UserDirectory.VIDEOS));

        // These must be in the same order as enum VideoMetadata
        this.properties.add ("height");
        this.properties.add ("width");
        this.properties.add ("res@duration");
    }

    public override MediaItem create (string          id,
                                      string          uri,
                                      SearchContainer parent,
                                      string[]        metadata)
                                      throws GLib.Error {
        var item = new VideoItem (id, parent, "");

        this.set_metadata (item, uri, metadata);

        return item;
    }

    protected override void set_metadata (MediaItem item,
                                          string    uri,
                                          string[]  metadata)
                                          throws GLib.Error {
        base.set_metadata (item, uri, metadata);

        var video = item as VideoItem;

        if (metadata[VideoMetadata.WIDTH] != "")
            video.width = int.parse (metadata[VideoMetadata.WIDTH]);

        if (metadata[VideoMetadata.HEIGHT] != "")
            video.height = int.parse (metadata[VideoMetadata.HEIGHT]);

        if (metadata[VideoMetadata.DURATION] != "")
            video.duration = int.parse (metadata[VideoMetadata.DURATION]);
    }
}

