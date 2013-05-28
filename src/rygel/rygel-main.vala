/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2012 Openismus GmbH.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *         Jens Georg <jensg@openismus.com>
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

using Gee;
using GUPnP;
using Posix;

internal class Rygel.Main : Object {
    private static int PLUGIN_TIMEOUT = 5;

    private PluginLoader plugin_loader;
    private ContextManager context_manager;
    private ArrayList <RootDeviceFactory> factories;
    private ArrayList <RootDevice> root_devices;

    private Configuration config;
    private LogHandler log_handler;

    private MainLoop main_loop;

    private int exit_code;

    public bool need_restart;

    private Main () throws GLib.Error {
        Environment.set_application_name (_(BuildConfig.PACKAGE_NAME));

        this.log_handler = LogHandler.get_default ();
        this.config = MetaConfig.get_default ();
        this.plugin_loader = new PluginLoader ();
        this.root_devices = new ArrayList <RootDevice> ();
        this.factories = new ArrayList <RootDeviceFactory> ();
        this.main_loop = new GLib.MainLoop (null, false);

        this.exit_code = 0;

        this.plugin_loader.plugin_available.connect (this.on_plugin_loaded);

        Unix.signal_add (SIGHUP, () => { this.restart (); return true; });
        Unix.signal_add (SIGINT, () => { this.exit (0); return false; });
        Unix.signal_add (SIGTERM, () => { this.exit (0); return false; });
    }

    public void exit (int exit_code) {
        this.exit_code = exit_code;

        this.root_devices = null;
        this.main_loop.quit ();
    }

    public void restart () {
        this.need_restart = true;

        this.exit (0);
    }

    private int run () {
        try {
            if (!this.config.get_upnp_enabled ()) {
                message (_("Rygel is running in streaming-only mode."));
            }
        } catch (Error error) { }

        this.main_loop.run ();

        return this.exit_code;
    }

    internal void dbus_available () {
        this.context_manager = this.create_context_manager ();
        this.plugin_loader.load_modules ();

        var timeout = PLUGIN_TIMEOUT;
        try {
            var config = MetaConfig.get_default ();
            timeout = config.get_int ("plugin",
                                      "TIMEOUT",
                                      PLUGIN_TIMEOUT,
                                      int.MAX);
        } catch (Error error) {};

        Timeout.add_seconds (timeout, () => {
            if (this.plugin_loader.list_plugins ().size == 0) {
                warning (ngettext ("No plugins found in %d second; giving up...",
                                   "No plugins found in %d seconds; giving up...",
                                   PLUGIN_TIMEOUT),
                         PLUGIN_TIMEOUT);

                this.exit (-82);
            }

            return false;
        });
    }


    private void on_plugin_loaded (PluginLoader plugin_loader,
                                   Plugin       plugin) {
        var iterator = this.factories.iterator ();
        while (iterator.next ()) {
            this.create_device.begin (plugin, iterator.get ());
        }
    }

    private ContextManager create_context_manager () {
        int port = 0;

        try {
            port = this.config.get_port ();
        } catch (GLib.Error err) {}

        var manager = ContextManager.create (port);

        manager.context_available.connect (this.on_context_available);
        manager.context_unavailable.connect (this.on_context_unavailable);

        return manager;
    }

    private void on_context_available (GUPnP.ContextManager manager,
                                       GUPnP.Context        context) {
        string[] ifaces = null;

        debug ("New network %s (%s) context available. IP: %s",
               context.network,
               context.interface,
               context.host_ip);

        try {
            ifaces = this.config.get_interfaces ();
        } catch (GLib.Error err) {}

        if (ifaces == null ||
            context.interface in ifaces||
            context.network in ifaces) {
            try {
                var factory = new RootDeviceFactory (context);
                this.factories.add (factory);

                var iterator = this.plugin_loader.list_plugins ().iterator ();
                while (iterator.next ()) {
                    this.create_device.begin (iterator.get (), factory);
                }
            } catch (GLib.Error err) {
                warning (_("Failed to create root device factory: %s"),
                         err.message);
            }
        } else {
            debug ("Ignoring network %s (%s) context.",
                   context.network,
                   context.interface);
        }
    }

    private void on_context_unavailable (GUPnP.ContextManager manager,
                                         GUPnP.Context        context) {
        debug ("Network %s (%s) context now unavailable. IP: %s",
               context.network,
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

    private async void create_device (Plugin            plugin,
                                      RootDeviceFactory factory) {
        // The call to factory.create(), although synchronous spins the
        // the mainloop and therefore might in turn triger some of the signal
        // handlers here that modify one of the lists that we might be iterating
        // while this function is called. Modification of an ArrayList while
        // iterating it is currently unsuppored and leads to a crash and that is
        // why defer to mainloop here.
        Idle.add (create_device.callback);
        yield;

        try {
            var device = factory.create (plugin);

            device.available = plugin.active &&
                               this.config.get_upnp_enabled ();

            // Due to pure evilness of unix sinals this might actually happen
            // if someone shuts down rygel while the call-back is running,
            // leading to a crash on shutdown
            if (this.root_devices != null) {
                this.root_devices.add (device);

                plugin.notify["active"].connect (this.on_plugin_active_notify);
            }
        } catch (GLib.Error error) {
            warning (_("Failed to create RootDevice for %s. Reason: %s"),
                     plugin.name,
                     error.message);
        }
    }

    private void on_plugin_active_notify (Object    obj,
                                          ParamSpec spec) {
        if (unlikely (this.root_devices == null)) {
            return;
        }

        var plugin = obj as Plugin;

        foreach (var device in this.root_devices) {
            if (device.resource_factory == plugin) {
                device.available = plugin.active;
            }
        }
    }

    private static void register_default_configurations () {

        var cmdline_config = CmdlineConfig.get_default ();

        MetaConfig.register_configuration (cmdline_config);
        MetaConfig.register_configuration (EnvironmentConfig.get_default ());

        try {
            var config_file = cmdline_config.get_config_file ();
            var user_config = new UserConfig (config_file);
            MetaConfig.register_configuration (user_config);
        } catch (Error error) {
            try {
                var user_config = UserConfig.get_default ();
                MetaConfig.register_configuration (user_config);
            } catch (Error err) {
                warning (_("Failed to load user configuration: %s"), err.message);
            }
        }
    }


    private static int main (string[] args) {
        Main main = null;
        DBusService service = null;

        var original_args = args;

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (BuildConfig.GETTEXT_PACKAGE,
                             BuildConfig.LOCALEDIR);
        Intl.bind_textdomain_codeset (BuildConfig.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (BuildConfig.GETTEXT_PACKAGE);

        try {
            // Parse commandline options
            CmdlineConfig.parse_args (ref args);
            Main.register_default_configurations ();
            MediaEngine.init ();

            main = new Main ();
            service = new DBusService (main);
            service.publish ();
        } catch (CmdlineConfigError.VERSION_ONLY err) {
            return 0;
        } catch (GLib.Error err) {
            error ("%s", err.message);
        }

        int exit_code = main.run ();
        if (service != null) {
            service.unpublish ();
        }

        if (main.need_restart) {
            Posix.execvp (original_args[0], original_args);
        }

        return exit_code;
    }
}

