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

using Rygel;
using Gee;
using Rygel.External.FreeDesktop;

private External.PluginFactory plugin_factory;

public void module_init (PluginLoader loader) {
    try {
        plugin_factory = new External.PluginFactory (loader);
    } catch (Error error) {
        message (_("Module “%s” could not connect to D-Bus session bus. "+
                   "Ignoring…"), External.Plugin.MODULE_NAME);
    }
}

public class Rygel.External.PluginFactory {
    private const string SERVICE_PREFIX = "org.gnome.UPnP.MediaServer2.";
    private const string GRILO_UPNP_PREFIX = SERVICE_PREFIX + "grl_upnp";

    FreeDesktop.DBusObject dbus_obj;
    PluginLoader           loader;
    IconFactory            icon_factory;

    public PluginFactory (PluginLoader loader) throws IOError, DBusError {
        this.icon_factory = new IconFactory ();

        this.dbus_obj = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         DBUS_SERVICE,
                                         DBUS_OBJECT_PATH,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
        this.loader = loader;

        this.load_plugins.begin ();
    }

    private async void load_plugins () throws DBusError {
        var services = yield this.dbus_obj.list_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                yield this.load_plugin_n_handle_error (service);
            }
        }

        yield this.load_activatable_plugins ();
    }

    private async void load_activatable_plugins () throws DBusError {
        var services = yield this.dbus_obj.list_activatable_names ();

        foreach (var service in services) {
            if (service.has_prefix (SERVICE_PREFIX) &&
                this.loader.get_plugin_by_name (service) == null) {
                yield this.load_plugin_n_handle_error (service);
            }
        }

        this.dbus_obj.name_owner_changed.connect (this.name_owner_changed);
    }

    private void name_owner_changed (FreeDesktop.DBusObject dbus_obj,
                                     string                 name,
                                     string                 old_owner,
                                     string                 new_owner) {
        var plugin = this.loader.get_plugin_by_name (name);

        if (plugin != null) {
            if (old_owner != "" && new_owner == "") {
                debug ("Service '%s' going down, deactivating it",
                       name);
                plugin.active = false;
            } else if (old_owner == "" && new_owner != "") {
                debug ("Service '%s' up again, activating it", name);
                plugin.active = true;
            }
        } else if (name.has_prefix (SERVICE_PREFIX)) {
            // Ah, new plugin available, lets use it
            this.load_plugin_n_handle_error.begin (name);
        }
    }

    private async void load_plugin_n_handle_error (string service_name) {
        try {
            yield this.load_plugin (service_name);
        } catch (Error error) {
            warning ("Failed to load external plugin '%s': %s",
                     service_name,
                     error.message);
        }
    }

    private async void load_plugin (string service_name)
                                    throws IOError, DBusError {
        if (this.loader.plugin_disabled (service_name)) {
            message ("Plugin '%s' disabled by user, ignoring..", service_name);

            return;
        }

        if (service_name.has_prefix (GRILO_UPNP_PREFIX)) {
            // We don't entertain UPnP sources
            return;
        }

        // org.gnome.UPnP.MediaServer2.NAME => /org/gnome/UPnP/MediaServer2/NAME
        var root_object = "/" + service_name.replace (".", "/");

        // Create proxy to MediaObject iface to get the display name through
        Properties props = yield Bus.get_proxy
                                        (BusType.SESSION,
                                         service_name,
                                         root_object,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

        HashTable<string,Variant> object_props;
        HashTable<string,Variant> container_props;

        object_props = yield props.get_all (MediaObjectProxy.IFACE);
        container_props = yield props.get_all (MediaContainerProxy.IFACE);

        var icon = yield this.icon_factory.create (service_name,
                                                   container_props);

        string title;
        var value = object_props.lookup ("DisplayName");
        if (value != null) {
            title = (string) value;
        } else {
            title = service_name;
        }

        var child_count = (uint) container_props.lookup ("ChildCount");
        var searchable = (bool) container_props.lookup ("Searchable");

        try {
            var plugin = new External.Plugin (service_name,
                                              title,
                                              child_count,
                                              searchable,
                                              root_object,
                                              icon);

            this.loader.add_plugin (plugin);
        } catch (Error err) {
            critical ("Failed to create root container for '%s': %s. " +
                      "Ignoring",
                      service_name,
                      err.message);
        }
    }
}
