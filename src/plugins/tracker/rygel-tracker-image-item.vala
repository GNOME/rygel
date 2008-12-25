/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Rygel;
using GUPnP;
using DBus;

/**
 * Represents Tracker image item.
 */
public class Rygel.TrackerImageItem : TrackerItem {
    private enum Metadata {
        FILE_NAME,
        MIME,
        SIZE,
        TITLE,
        CREATOR,
        WIDTH,
        HEIGHT,
        ALBUM,
        IMAGE_DATE,
        DATE,
        LAST_KEY
    }

    public TrackerImageItem (string              id,
                             string              path,
                             TrackerContainer    parent) throws GLib.Error {
        base (id, path, parent);
    }

    public override void fetch_metadata () throws GLib.Error {
        string[] keys = new string[Metadata.LAST_KEY];
        keys[Metadata.FILE_NAME] = "File:Name";
        keys[Metadata.MIME] = "File:Mime";
        keys[Metadata.SIZE] = "File:Size";
        keys[Metadata.TITLE] = "Video:Title";
        keys[Metadata.CREATOR] = "Image:Creator";
        keys[Metadata.WIDTH] = "Image:Width";
        keys[Metadata.HEIGHT] = "Image:Height";
        keys[Metadata.ALBUM] = "Image:Album";
        keys[Metadata.IMAGE_DATE] = "Image:Date";
        keys[Metadata.DATE] = "DC:Date";
        string[] values = null;

        /* TODO: make this async */
        try {
            values = this.parent.metadata.Get (parent.category, path, keys);
        } catch (GLib.Error error) {
            critical ("failed to get metadata for %s: %s\n",
                      path,
                      error.message);

            return;
        }

        if (values[Metadata.TITLE] != "")
            this.title = values[Metadata.TITLE];
        else
            /* If title wasn't provided, use filename instead */
            this.title = values[Metadata.FILE_NAME];

        if (values[Metadata.SIZE] != "")
            this.res.size = values[Metadata.SIZE].to_int ();

        if (values[Metadata.WIDTH] != "")
            this.res.width = values[Metadata.WIDTH].to_int ();

        if (values[Metadata.HEIGHT] != "")
            this.res.height = values[Metadata.HEIGHT].to_int ();

        if (values[Metadata.SIZE] != "")
            this.res.size = values[Metadata.SIZE].to_int ();

        if (values[Metadata.DATE] != "") {
            this.date = seconds_to_iso8601 (values[Metadata.DATE]);
        } else {
            this.date = seconds_to_iso8601 (values[Metadata.IMAGE_DATE]);
        }

        // FIXME: (Leaky) Hack to assign the string to weak fields
        string *mime = #values[Metadata.MIME];
        this.res.mime_type = mime;
        this.author = values[Metadata.CREATOR];
        this.album = values[Metadata.ALBUM];
        string *uri = this.uri_from_path (path);
        this.res.uri = uri;
    }
}

