/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;
using Gee;
using Tracker;

/**
 * Represents the root container for Tracker media content hierarchy.
 */
public class Rygel.Tracker.RootContainer : Rygel.SimpleContainer {
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker3.Miner.Files";

    public static Sparql.Connection connection;

    public RootContainer (string title) throws Error {
        if (RootContainer.connection == null) {
            RootContainer.connection = Sparql.Connection.bus_new (TRACKER_SERVICE, null);
        }

        base.root (title);

        if (this.get_bool_config_without_error ("share-music")) {
            this.add_child_container (new Music ("Music", this, "Music"));
        }

        if (this.get_bool_config_without_error ("share-videos")) {
            this.add_child_container (new Videos ("Videos", this, "Videos"));
        }

        if (this.get_bool_config_without_error ("share-pictures")) {
            this.add_child_container (new Pictures ("Pictures",
                                                    this,
                                                    "Pictures"));
        }
    }

    private bool get_bool_config_without_error (string key) {
        var value = true;
        var config = MetaConfig.get_default ();

        try {
            value = config.get_bool ("Tracker3", key);
        } catch (GLib.Error error) {}

        return value;
    }
}
