/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using CStuff;
using Gee;
using GUPnP;

public class Rygel.Main : Object {
    private PluginLoader plugin_loader;
    private ContextManager context_manager;
    private ArrayList <RootDeviceFactory> factories;
    private ArrayList <RootDevice> root_devices;

    private Configuration config;
    private LogHandler log_handler;

    private MainLoop main_loop;

    private int exit_code;

    private Main () throws GLib.Error {
        Environment.set_application_name (_(BuildConfig.PACKAGE_NAME));

        this.log_handler = LogHandler.get_default ();
        this.config = MetaConfig.get_default ();
        this.plugin_loader = new PluginLoader ();
        this.root_devices = new ArrayList <RootDevice> ();
        this.factories = new ArrayList <RootDeviceFactory> ();
        this.context_manager = this.create_context_manager ();
        this.main_loop = new GLib.MainLoop (null, false);

        this.exit_code = 0;

        this.plugin_loader.plugin_available += this.on_plugin_loaded;

        Utils.on_application_exit (this.application_exit_cb);
    }

    public void exit (int exit_code) {
        this.exit_code = exit_code;
        this.main_loop.quit ();
    }

    private int run () {
        this.plugin_loader.load_plugins ();

        this.main_loop.run ();

        return this.exit_code;
    }

    private void application_exit_cb () {
        this.exit (0);
    }

    private void on_plugin_loaded (PluginLoader plugin_loader,
                                   Plugin       plugin) {
        var iterator = this.factories.iterator ();
        while (iterator.next ()) {
            this.create_device (plugin, iterator.get ());
        }
    }

    private ContextManager create_context_manager () {
        int port = 0;

        try {
            port = this.config.get_port ();
        } catch (GLib.Error err) {}

        var manager = new ContextManager (null, port);

        manager.context_available.connect (this.on_context_available);
        manager.context_unavailable.connect (this.on_context_unavailable);

        return manager;
    }

    private void on_context_available (GUPnP.ContextManager manager,
                                       GUPnP.Context        context) {
        string iface = null;

        debug ("new network context %s (%s) available.",
               context.interface,
               context.host_ip);

        try {
            iface = this.config.get_interface ();
        } catch (GLib.Error err) {}

        if (iface == null || iface == context.interface) {
            var factory = new RootDeviceFactory (context);
            this.factories.add (factory);

            var iterator = this.plugin_loader.list_plugins ().iterator ();
            while (iterator.next ()) {
                this.create_device (iterator.get (), factory);
            }
        } else {
            debug ("Ignoring network context %s (%s).",
                   context.interface,
                   context.host_ip);
        }
    }

    private void on_context_unavailable (GUPnP.ContextManager manager,
                                         GUPnP.Context        context) {
        debug ("Network context %s (%s) now unavailable.",
               context.interface,
               context.host_ip);

        var factory_iter = this.factories.iterator ();
        while (factory_iter.next ()) {
            if (context == factory_iter.get ().context) {
                factory_iter.remove ();
            }
        }

        var device_iter = this.root_devices.iterator ();
        while (device_iter.next ()) {
            if (context == device_iter.get ().context) {
                device_iter.remove ();
            }
        }
    }

    private void create_device (Plugin            plugin,
                                RootDeviceFactory factory) {
        try {
            var device = factory.create (plugin);

            device.available = plugin.available;

            this.root_devices.add (device);

            plugin.notify["available"] += this.on_plugin_notify;
        } catch (GLib.Error error) {
            warning ("Failed to create RootDevice for %s. Reason: %s\n",
                    plugin.name,
                    error.message);
        }
    }

    private void on_plugin_notify (Plugin    plugin,
                                   ParamSpec spec) {
        foreach (var device in this.root_devices) {
            if (device.resource_factory == plugin) {
                device.available = plugin.available;
            }
        }
    }

    private static int main (string[] args) {
        Main main;
        DBusService service;

        try {
            // Parse commandline options
            CmdlineConfig.parse_args (ref args);

            // initialize gstreamer
            var dummy_args = new string[0];
            Gst.init (ref dummy_args);

            main = new Main ();
            service = new DBusService (main);
        } catch (DBus.Error err) {
            warning ("Failed to start D-Bus service: %s", err.message);
        } catch (CmdlineConfigError.VERSION_ONLY err) {
            return 0;
        } catch (GLib.Error err) {
            error ("%s", err.message);

            return -1;
        }

        int exit_code = main.run ();

        return exit_code;
    }
}

