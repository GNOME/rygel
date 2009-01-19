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
using GUPnP;
using DBus;

/**
 * Represents Tracker item.
 */
public abstract class Rygel.TrackerItem : MediaItem {
    protected TrackerContainer parent;
    protected string path;

    public TrackerItem (string           id,
                        string           path,
                        TrackerContainer parent) throws GLib.Error {
        base (id, parent.id, "", parent.child_class, parent.http_server);

        this.path = path;
        this.parent = parent;

        this.fetch_metadata ();
    }

    protected string seconds_to_iso8601 (string seconds) {
        string date;

        if (seconds != "") {
            TimeVal tv = TimeVal ();

            tv.tv_sec = seconds.to_int ();
            tv.tv_usec = 0;

            date = tv.to_iso8601 ();
        } else {
            date = "";
        }

        return date;
    }

    protected string uri_from_path (string path) {
        return "file://%s".printf (path);
    }

    protected abstract void fetch_metadata () throws GLib.Error;
}

