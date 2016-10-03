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
using Rygel.MPRIS.FreeDesktop;

private MPRIS.PluginFactory plugin_factory;

public void module_init (PluginLoader loader) {
    try {
        plugin_factory = new MPRIS.PluginFactory (loader);
    } catch (IOError error) {
        message (_("Module “%s” could not connect to D-Bus session bus. "+
                   "Ignoring…"), MPRIS.Plugin.MODULE_NAME);
    }
}

public class Rygel.MPRIS.PluginFactory {
    private const string DBUS_SERVICE = "org.freedesktop.DBus";
    private const string DBUS_OBJECT = "/org/freedesktop/DBus";

    private const string SERVICE_PREFIX = "org.mpris.MediaPlayer2.";
    private const string MEDIA_PLAYER_PATH = "/org/mpris/MediaPlayer2";

    FreeDesktop.DBusObject dbus_obj;
    PluginLoader           loader;

    public PluginFactory (PluginLoader loader) throws IOError {
        this.dbus_obj = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         DBUS_SERVICE,
                                         DBUS_OBJECT,
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
                debug ("Service '%s' going down, Deactivating it",
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
        if (loader.plugin_disabled (service_name)) {
            message ("Plugin '%s' disabled by user, ignoring..", service_name);

            return;
        }

        try {
            yield this.load_plugin (service_name);
        } catch (IOError error) {
            warning ("Failed to load MPRIS2 plugin '%s': %s",
                     service_name,
                     error.message);
        }
    }

    private async void load_plugin (string service_name) throws IOError {
        MediaPlayer.PlayerProxy player =
                                        yield Bus.get_proxy (BusType.SESSION,
                                                             service_name,
                                                             MEDIA_PLAYER_PATH);

        if (!player.can_control) {
            message (_("MPRIS interface at %s is read-only. Ignoring."),
                     service_name);

            return;
        }

        var plugin = new MPRIS.Plugin (service_name, player);

        this.loader.add_plugin (plugin);
    }
}
