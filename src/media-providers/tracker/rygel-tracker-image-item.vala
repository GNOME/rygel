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

public class Rygel.TrackerImageItem : MediaItem {
    private TrackerContainer parent;
    private string path;
    private GUPnP.Context context;

    private dynamic DBus.Object metadata;

    string[] keys;

    public TrackerImageItem (string              id,
                             string              path,
                             TrackerContainer    parent,
                             dynamic DBus.Object metadata,
                             GUPnP.Context       context) {
        this.id = id;
        this.path = path;
        this.parent = parent;
        this.parent_id = parent.id;
        this.upnp_class = parent.child_class;

        this.metadata = metadata;
        this.context = context;

        keys = new string[] {"File:Name",
                             "File:Mime",
                             "Image:Title",
                             "Image:Creator",
                             "Image:Width",
                             "Image:Height",
                             "Image:Album",
                             "Image:Date",
                             "DC:Date"};
    }

    public override void serialize (DIDLLiteWriter didl_writer) {
        string[] values = null;

        /* TODO: make this async */
        try {
            values = this.metadata.Get (parent.tracker_category, path, keys);
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
            this.width = values[4].to_int ();

        if (values[5] != "")
            this.height = values[5].to_int ();

        if (values[8] != "") {
            this.date = seconds_to_iso8601 (values[8]);
        } else {
            this.date = seconds_to_iso8601 (values[7]);
        }

        this.mime = values[1];
        this.author = values[3];
        this.album = values[6];
        this.uri = this.uri_from_path (path);

        base.serialize (didl_writer);
    }

    private string seconds_to_iso8601 (string seconds) {
        string date;

        if (seconds != "") {
            TimeVal tv;

            tv.tv_sec = seconds.to_int ();
            tv.tv_usec = 0;

            date = tv.to_iso8601 ();
        } else {
            date = "";
        }

        return date;
    }

    private string uri_from_path (string path) {
        string escaped_path = Uri.escape_string (path, "/", true);

        return "http://%s:%u%s".printf (this.context.host_ip,
                                        this.context.port,
                                        escaped_path);
    }
}

