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
 * Represents Tracker video item.
 */
public class Rygel.TrackerVideoItem : TrackerItem {
    private enum Metadata {
        FILE_NAME,
        MIME,
        SIZE,
        TITLE,
        AUTHOR,
        WIDTH,
        HEIGHT,
        DATE,
        LAST_KEY
    }

    public TrackerVideoItem (string              id,
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
        keys[Metadata.AUTHOR] = "Video:Author";
        keys[Metadata.WIDTH] = "Video:Width";
        keys[Metadata.HEIGHT] = "Video:Height";
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

        this.date = this.seconds_to_iso8601 (values[Metadata.DATE]);
        this.res.mime_type = values[Metadata.MIME];
        this.author = values[Metadata.AUTHOR];
        this.res.uri = this.uri_from_path (path);
    }
}

