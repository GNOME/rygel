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
    public TrackerVideoItem (string              id,
                             string              path,
                             TrackerContainer    parent) throws GLib.Error {
        keys = new string[] {"File:Name",
                             "File:Mime",
                             "Video:Title",
                             "Video:Author",
                             "Video:Width",
                             "Video:Height",
                             "DC:Date"};

        base (id, path, parent);
    }

    public override void fetch_metadata () throws GLib.Error {
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

        if (values[2] != "")
            this.title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            this.title = values[0];

        if (values[4] != "")
            this.res.width = values[4].to_int ();

        if (values[5] != "")
            this.res.height = values[5].to_int ();

        this.date = this.seconds_to_iso8601 (values[6]);
        // FIXME: (Leaky) Hack to assign the string to weak fields
        string *mime = #values[1];
        this.res.mime_type = mime;
        this.author = values[3];
        string *uri = this.uri_from_path (path);
        this.res.uri = uri;
    }
}

