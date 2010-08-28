/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009,2010 Nokia Corporation.
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
using FreeDesktop;

private MPRIS.PluginFactory plugin_factory;

public void module_init (PluginLoader loader) {
    try {
        plugin_factory = new MPRIS.PluginFactory (loader);
    } catch (DBus.Error error) {
        critical ("Failed to fetch list of MPRIS services: %s\n",
                  error.message);
    }
}

public class Rygel.MPRIS.PluginFactory {
    private const string DBUS_SERVICE = "org.freedesktop.DBus";
    private const string DBUS_OBJECT = "/org/freedesktop/DBus";

    private const string SERVICE_PREFIX = "org.mpris.MediaPlayer2.";
    private const string MEDIA_PLAYER_PATH = "/org/mpris/MediaPlayer2";

    DBusObject      dbus_obj;
    DBus.Connection connection;
    PluginLoader    loader;

    public PluginFactory (PluginLoader loader) throws DBus.Error {
        this.connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.dbus_obj = this.connection.get_object (DBUS_SERVICE, DBUS_OBJECT)
                        as DBusObject;
        this.loader = loader;

        this.load_plugins.begin ();
    }

    private async void load_plugins () throws DBus.Error {
        var services = yield this.dbus_obj.list_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                yield this.load_plugin (service);
            }
        }

        yield this.load_activatable_plugins ();
    }

    private async void load_activatable_plugins () throws DBus.Error {
        var services = yield this.dbus_obj.list_activatable_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                yield this.load_plugin (service);
            }
        }

        this.dbus_obj.name_owner_changed.connect (this.name_owner_changed);
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
                debug ("Service '%s' up again, marking it as available", name);
                plugin.available = true;
            }
        } else if (name.has_prefix (SERVICE_PREFIX)) {
                // Ah, new plugin available, lets use it
                this.load_plugin.begin (name);
        }
    }

    private async void load_plugin (string service_name) {
        // Create proxy to MediaObject iface to get the display name through
        var props = this.connection.get_object (service_name, MEDIA_PLAYER_PATH)
                    as Properties;

        HashTable<string,Value?> props_hash;

        try {
            props_hash = yield props.get_all (MediaPlayerProxy.IFACE);
        } catch (DBus.Error err) {
            warning ("Failed to fetch properties of plugin %s: %s.",
                     service_name,
                     err.message);

            return;
        }

        var title = (string) props_hash.lookup ("Identity");
        if (title == null) {
            title = service_name;
        }

        var mime_types = (string[]) props_hash.lookup ("SupportedMimeTypes");
        var schemes = (string[]) props_hash.lookup ("SupportedUriSchemes");

        var plugin = new MPRIS.Plugin (service_name,
                                       title,
                                       mime_types,
                                       schemes);

        this.loader.add_plugin (plugin);
    }
}
