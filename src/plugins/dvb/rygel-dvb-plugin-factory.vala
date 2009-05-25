/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Gee;
using CStuff;

private DVBPluginFactory plugin_factory;

[ModuleInit]
public void module_init (PluginLoader loader) {
    try {
        plugin_factory = new DVBPluginFactory (loader);
    } catch (DBus.Error error) {
        critical ("Failed to fetch list of external services: %s\n",
                error.message);
    }
}

public class DVBPluginFactory {
    private const string DBUS_SERVICE = "org.freedesktop.DBus";
    private const string DBUS_OBJECT = "/org/freedesktop/DBus";
    private const string DBUS_IFACE = "org.freedesktop.DBus";

    private const string TRACKER_SERVICE = "org.gnome.DVB";

    dynamic DBus.Object dbus_obj;
    PluginLoader        loader;

    public DVBPluginFactory (PluginLoader loader) throws DBus.Error {
        var connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                               DBUS_OBJECT,
                                               DBUS_IFACE);
        this.loader = loader;

        dbus_obj.StartServiceByName (TRACKER_SERVICE,
                                     (uint32) 0,
                                     this.start_service_cb);
    }

    private void start_service_cb (uint32 status, GLib.Error err) {
        if (err != null) {
            warning ("Failed to start DVB service: %s\n",
                     err.message);
            warning ("DVB plugin disabled.\n");

            return;
        }

        this.loader.add_plugin (new DVBPlugin ());
    }
}

