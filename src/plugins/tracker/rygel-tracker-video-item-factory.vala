/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
 *          Jens Georg <jensg@openismus.com>
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
using Tracker;

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
    private const string CATEGORY_IRI = "http://www.tracker-project.org/" +
                                        "temp/nmm#Video";

    public VideoItemFactory () {
        var upload_folder = Environment.get_user_special_dir
                                        (UserDirectory.VIDEOS);
        try {
            var config = MetaConfig.get_default ();
            upload_folder = config.get_video_upload_folder ();
        } catch (Error error) {};

        base (CATEGORY, CATEGORY_IRI, VideoItem.UPNP_CLASS, upload_folder);

        // These must be in the same order as enum VideoMetadata
        this.properties.add ("height");
        this.properties.add ("width");
        this.properties.add ("res@duration");
    }

    public override MediaFileItem create (string          id,
                                          string          uri,
                                          SearchContainer parent,
                                          Sparql.Cursor   metadata)
                                          throws GLib.Error {
        var item = new VideoItem (id, parent, "");

        this.set_metadata (item, uri, metadata);

        return item;
    }

    protected override void set_metadata (MediaFileItem item,
                                          string        uri,
                                          Sparql.Cursor metadata)
                                          throws GLib.Error {
        base.set_metadata (item, uri, metadata);

        this.set_ref_id (item, "AllVideos");

        var video = item as VideoItem;

        if (metadata.is_bound (VideoMetadata.WIDTH))
            video.width = (int) metadata.get_integer (VideoMetadata.WIDTH);

        if (metadata.is_bound (VideoMetadata.HEIGHT))
            video.height = (int) metadata.get_integer (VideoMetadata.HEIGHT);

        if (metadata.is_bound (VideoMetadata.DURATION))
            video.duration = (int) metadata.get_integer
                                        (VideoMetadata.DURATION);
    }
}

