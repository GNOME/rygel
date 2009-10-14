/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
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
using FreeDesktop;

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

    private const string SERVICE_PREFIX = "org.gnome.UPnP.MediaServer1.";

    DBusObject dbus_obj;
    DBus.Connection  connection;
    PluginLoader     loader;

    public ExternalPluginFactory (PluginLoader loader) throws DBus.Error {
        this.connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                               DBUS_OBJECT)
                                               as DBusObject;
        this.loader = loader;

        this.load_plugins ();
    }

    private void load_plugins () throws DBus.Error {
        var services = this.dbus_obj.list_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                this.loader.add_plugin (new ExternalPlugin (this.connection,
                                                            service));
            }
        }

        this.load_activatable_plugins ();
    }

    private void load_activatable_plugins () throws DBus.Error {
        var services = this.dbus_obj.list_activatable_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                this.loader.add_plugin (new ExternalPlugin (this.connection,
                                                            service));
            }
        }

        this.dbus_obj.name_owner_changed += this.name_owner_changed;
    }

    private void name_owner_changed (DBusObject dbus_obj,
                                     string     name,
                                     string     old_owner,
                                     string     new_owner) {
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
