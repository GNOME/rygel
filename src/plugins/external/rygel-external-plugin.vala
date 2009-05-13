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

private const string DBUS_SERVICE = "org.freedesktop.DBus";
private const string DBUS_OBJECT = "/org/freedesktop/DBus";
private const string DBUS_IFACE = "org.freedesktop.DBus";
private const string PROPS_IFACE = "org.freedesktop.DBus.Properties";

private const string OBJECT_IFACE = "org.Rygel.MediaObject1";
private const string SERVICE_PREFIX = "org.Rygel.MediaServer1.";

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
    dynamic DBus.Object dbus_obj;
    DBus.Connection     connection;
    PluginLoader        loader;

    public ExternalPluginFactory (PluginLoader loader) throws DBus.Error {
        this.connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                               DBUS_OBJECT,
                                               DBUS_IFACE);
        this.loader = loader;

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

        dbus_obj.NameOwnerChanged += this.name_owner_changed;
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

public class ExternalPlugin : Plugin {
    // class-wide constants
    public string service_name;
    public string root_object;

    public ExternalPlugin (DBus.Connection     connection,
                           string              service_name) {
        // org.Rygel.MediaServer1.NAME => /org/Rygel/MediaServer1/NAME
        var root_object = "/" + service_name.replace (".", "/");

        // Create proxy to MediaObject iface to get the display name through
        dynamic DBus.Object props = connection.get_object (service_name,
                                                           root_object,
                                                           PROPS_IFACE);
        Value value;
        props.Get (OBJECT_IFACE, "display-name", out value);
        var title = value.get_string ();

        base (service_name, title);

        this.service_name = service_name;
        this.root_object = root_object;

        // We only implement a ContentDirectory service
        var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                              ContentDirectory.UPNP_TYPE,
                                              ContentDirectory.DESCRIPTION_PATH,
                                              typeof (ExternalContentDir));

        this.add_resource (resource_info);
    }
}
