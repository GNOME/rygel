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

    private static string OBJECT_IFACE = "org.gnome.UPnP.MediaObject1";
    private static string CONTAINER_IFACE = "org.gnome.UPnP.MediaContainer1";
    private static string ITEM_IFACE = "org.gnome.UPnP.MediaItem1";

    private const string SERVICE_PREFIX = "org.gnome.UPnP.MediaServer1.";

    DBusObject      dbus_obj;
    DBus.Connection connection;
    PluginLoader    loader;

    public ExternalPluginFactory (PluginLoader loader) throws DBus.Error {
        this.connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                               DBUS_OBJECT)
                                               as DBusObject;
        this.loader = loader;

        this.load_plugins.begin ();
    }

    private async void load_plugins () throws DBus.Error {
        var services = yield this.dbus_obj.list_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                yield this.load_plugin (this.connection, service);
            }
        }

        yield this.load_activatable_plugins ();
    }

    private async void load_activatable_plugins () throws DBus.Error {
        var services = yield this.dbus_obj.list_activatable_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                yield this.load_plugin (this.connection, service);
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
                this.load_plugin.begin (this.connection, name);
        }
    }

    private async void load_plugin (DBus.Connection connection,
                                    string          service_name) {
        // org.gnome.UPnP.MediaServer1.NAME => /org/gnome/UPnP/MediaServer1/NAME
        var root_object = "/" + service_name.replace (".", "/");

        // Create proxy to MediaObject iface to get the display name through
        var props = connection.get_object (service_name,
                                           root_object)
                                           as Properties;

        HashTable<string,Value?> object_props;
        HashTable<string,Value?> container_props;

        try {
            object_props = yield props.get_all (OBJECT_IFACE);
            container_props = yield props.get_all (CONTAINER_IFACE);
        } catch (DBus.Error err) {
            warning ("Failed to fetch properties of plugin %s: %s.",
                     service_name,
                     err.message);

            return;
        }

        var icon = yield fetch_icon (connection, service_name, container_props);

        string title;
        var value = object_props.lookup ("DisplayName");
        if (value != null) {
            title = value.get_string ();
        } else {
            title = service_name;
        }

        var plugin = new ExternalPlugin (service_name,
                                         title,
                                         root_object,
                                         icon);

        this.loader.add_plugin (plugin);
    }

    public async IconInfo? fetch_icon (DBus.Connection connection,
                                       string          service_name,
                                       HashTable<string,Value?>
                                                       container_props) {
        var value = container_props.lookup ("Icon");
        if (value == null) {
            // Seems no icon is provided, nevermind
            return null;
        }

        var icon_path = value.get_string ();
        var props = connection.get_object (service_name,
                                           icon_path)
                                           as Properties;

        HashTable<string,Value?> item_props;
        try {
            item_props = yield props.get_all (ITEM_IFACE);
        } catch (DBus.Error err) {
            warning ("Error fetching icon properties from %s", service_name);

            return null;
        }

        value = item_props.lookup ("MIMEType");
        var icon = new IconInfo (value.get_string ());

        value = item_props.lookup ("URLs");
        weak string[] uris = (string[]) value.get_boxed ();
        if (uris != null && uris[0] != null) {
            icon.uri = uris[0];
        }

        value = item_props.lookup ("Size");
        if (value != null) {
            icon.size = value.get_int ();
        }

        value = item_props.lookup ("Width");
        if (value != null) {
            icon.width = value.get_int ();
        }

        value = item_props.lookup ("Height");
        if (value != null) {
            icon.height = value.get_int ();
        }

        value = item_props.lookup ("ColorDepth");
        if (value != null) {
            icon.depth = value.get_int ();
        }

        return icon;
    }
}
