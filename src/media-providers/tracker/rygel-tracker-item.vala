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

public abstract class Rygel.TrackerItem : MediaItem {
    protected TrackerContainer parent;
    protected string path;

    protected dynamic DBus.Object metadata;

    protected string[] keys;

    public TrackerItem (string              id,
                        string              path,
                        TrackerContainer    parent) {
        this.id = id;
        this.path = path;
        this.parent = parent;
        this.parent_id = parent.id;
        this.upnp_class = parent.child_class;
    }

    protected string seconds_to_iso8601 (string seconds) {
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

    protected string uri_from_path (string path) {
        string escaped_path = Uri.escape_string (path, "/", true);

        return "http://%s:%u%s".printf (this.parent.context.host_ip,
                                        this.parent.context.port,
                                        escaped_path);
    }
}

