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
 * Container listing all available keywords (tags) in Tracker DB.
 */
public class Rygel.TrackerKeywords : Rygel.SimpleContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    private const string KEYWORDS_PATH = "/org/freedesktop/Tracker/Keywords";
    private const string KEYWORDS_IFACE = "org.freedesktop.Tracker.Keywords";

    private const string SERVICE = "Files";
    private const string TITLE = "Tags";

    public dynamic DBus.Object keywords;

    public TrackerKeywords (string         id,
                            MediaContainer parent) {
        base (id, parent, TITLE);

        try {
            this.create_proxies ();

            /* FIXME: We need to hook to some tracker signals to keep
             *        this field up2date at all times
             */
            this.keywords.GetList (SERVICE, on_get_keywords_cb);
        } catch (GLib.Error error) {
            critical ("Failed to create to Session bus: %s\n",
                      error.message);
        }
    }

    private void on_get_keywords_cb (string[][] keywords_list,
                                     GLib.Error error) {
        if (error != null) {
            critical ("error getting all keywords: %s", error.message);

            return;
        }

        /* Iterate through all the values */
        for (uint i = 0; i < keywords_list.length; i++) {
            string keyword = keywords_list[i][0];

            var keywords = new string[] { keyword };

            var container = new TrackerSearchContainer (keyword,
                                                        this,
                                                        keyword,
                                                        SERVICE,
                                                        keywords);

            this.add_child (container);
        }

        this.updated ();
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.keywords = connection.get_object (TRACKER_SERVICE,
                                               KEYWORDS_PATH,
                                               KEYWORDS_IFACE);
    }
}

