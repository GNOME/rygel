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

private ExternalPluginFactory plugin_factory;

[ModuleInit]
public void module_init (PluginLoader loader) {
    try {
        plugin_factory = new ExternalPluginFactory (loader);
    } catch (DBus.Error error) {
        critical ("Failed to fetch list of external services: %s\n",
                error.message);
    }
}

public class ExternalPluginFactory {
    private const string DBUS_SERVICE = "org.freedesktop.DBus";
    private const string DBUS_OBJECT = "/org/freedesktop/DBus";
    private const string DBUS_IFACE = "org.freedesktop.DBus";

    private const string SERVICE_PREFIX = "org.gnome.UPnP.MediaServer1.";

    dynamic DBus.Object dbus_obj;
    DBus.Connection     connection;
    PluginLoader        loader;

    bool activatable; // Indicated if we have listed activatable services yet

    public ExternalPluginFactory (PluginLoader loader) throws DBus.Error {
        this.connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                               DBUS_OBJECT,
                                               DBUS_IFACE);
        this.loader = loader;

        this.activatable = false;
        dbus_obj.ListNames (this.list_names_cb);
    }

    private void list_names_cb (string[]   services,
                                GLib.Error err) {
        if (err != null) {
            critical ("Failed to fetch list of external services: %s\n",
                      err.message);

            return;
        }

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX)) {
                this.loader.add_plugin (new ExternalPlugin (this.connection,
                                                            service));
            }
        }

        if (this.activatable) {
            // Activatable services are already taken-care of, now we can
            // just relax but keep a watch on bus for plugins coming and
            // going away on the fly.
            dbus_obj.NameOwnerChanged += this.name_owner_changed;
        } else {
            dbus_obj.ListActivatableNames (this.list_names_cb);
            this.activatable = true;
        }
    }

    private void name_owner_changed (dynamic DBus.Object dbus_obj,
                                     string              name,
                                     string              old_owner,
                                     string              new_owner) {
        var plugin = this.loader.get_plugin_by_name (name);

        if (plugin != null) {
            if (old_owner != "" && new_owner == "") {
                debug ("Service '%s' going down, marking it as unavailable",
                        name);
                plugin.available = false;
            } else if (old_owner == "" && new_owner != "") {
                debug ("Service '%s' up again, marking it as available",
                        name);
                plugin.available = true;
            }
        } else if (name.has_prefix (SERVICE_PREFIX)) {
                // Ah, new plugin available, lets use it
                this.loader.add_plugin (new ExternalPlugin (this.connection,
                                                            name));
        }
    }
}
