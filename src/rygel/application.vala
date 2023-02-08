// SPDX-License-Identifier: LGPL-2.1-or-later
//
using Gee;
using GUPnP;

public class Rygel.Application : GLib.Application {
    // Default time to wait for plugins showing up
    private static int PLUGIN_TIMEOUT = 5;

    private PluginLoader plugin_loader;
    private ContextManager context_manager;
    private ArrayList <RootDeviceFactory> factories;
    private ArrayList <RootDevice> root_devices;

    private Configuration config;
    private LogHandler log_handler;
    private Acl acl;
    private DBusService service;

    private bool activation_pending = false;

    public Application() {
        Object(application_id : "org.gnome.Rygel",
               flags : ApplicationFlags.HANDLES_COMMAND_LINE |
                       ApplicationFlags.ALLOW_REPLACEMENT);

        this.add_main_option_entries (CmdlineConfig.OPTIONS);

        Unix.signal_add (ProcessSignal.INT, () => { this.release (); return false; });
        Unix.signal_add (ProcessSignal.TERM, () => { this.release (); return false; });
        Unix.signal_add (ProcessSignal.HUP, () => { this.release (); return false; });
    }

    public override bool dbus_register (DBusConnection connection, string object_path) throws Error {
        if (!base.dbus_register (connection, object_path)) {
            return false;
        }

        service = new DBusService(this);
        service.publish (connection);

        return true;
    }

    public override int handle_local_options (VariantDict options) {
        int count;
        if (options.lookup ("version", "b", out count)) {
            print ("%s\n", BuildConfig.PACKAGE_STRING);

            return 0;
        }

        // Further options to be handled remotely
        return -1;
    }

    public override int command_line (GLib.ApplicationCommandLine command_line) {
        var options = command_line.get_options_dict ();
        if (options.contains ("shutdown")) {
            release ();

            return 0;
        }

        CmdlineConfig.get_default ().set_options (options);

        activate ();

        return -1;
    }

    private void register_default_configurations () {

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

    private void run_everything () {
        this.register_default_configurations ();

        this.log_handler = LogHandler.get_default ();
        this.config = MetaConfig.get_default ();
        this.plugin_loader = new PluginLoader ();
        this.root_devices = new ArrayList <RootDevice> ();
        this.factories = new ArrayList <RootDeviceFactory> ();
        this.acl = new Acl ();

        this.plugin_loader.plugin_available.connect (this.on_plugin_loaded);
        this.context_manager = this.create_context_manager ();
        this.plugin_loader.load_modules ();
        this.activation_pending = false;

        var timeout = PLUGIN_TIMEOUT;
        try {
            var config = MetaConfig.get_default ();
            timeout = config.get_int ("plugin",
                                      "TIMEOUT",
                                      0,
                                      int.MAX);
        } catch (Error error) {};

        if (timeout == 0) {
            debug ("Plugin timeout disabled...");

            return;
        }

        Timeout.add_seconds (timeout, () => {
            if (this.plugin_loader.list_plugins ().size == 0) {
                warning (ngettext ("No plugins found in %d second; giving up…",
                                   "No plugins found in %d seconds; giving up…",
                                   PLUGIN_TIMEOUT),
                         PLUGIN_TIMEOUT);
                this.release ();
            }

            return false;
        });
    }

    public override void activate () {
        base.activate ();
        if (this.context_manager == null || this.activation_pending) {
            hold ();
            if (ApplicationFlags.REPLACE in this.flags) {
                this.activation_pending = true;
                // Delay context manager creation to give the other instance a chance to
                // give up the socket
                Timeout.add_seconds (1, () => { this.run_everything (); return false; });
            } else {
                this.run_everything ();
            }
        }
    }

    public override void startup () {
        base.startup ();

        message (_("Rygel v%s starting…"), BuildConfig.PACKAGE_VERSION);
    }

    public override void shutdown () {
        this.root_devices = null;
        base.shutdown ();
    }

    public override bool name_lost () {
        this.root_devices = null;
        this.release ();

        return true;
    }

    private void on_plugin_loaded (PluginLoader plugin_loader,
                                   Plugin       plugin) {
        var iterator = this.factories.iterator ();
        while (iterator.next ()) {
            this.create_device.begin (plugin, iterator.get ());
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

            device.available = plugin.active;

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


    private ContextManager create_context_manager () {
        int port = 0;
        bool ipv6 = false;

        try {
            port = this.config.get_port ();
        } catch (GLib.Error err) {}

        try {
            ipv6 = this.config.get_bool ("general", "ipv6");
        } catch (GLib.Error err) {
            debug ("No ipv6 config key found, using default %s", ipv6.to_string ());
        }

        // INVALID means "all"
        var family = GLib.SocketFamily.INVALID;
        if (!ipv6) {
            family = GLib.SocketFamily.IPV4;
        }

        var manager = ContextManager.create_full (GSSDP.UDAVersion.VERSION_1_0,
                                                  family,
                                                  port);

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
               context.address.to_string ());

        context.acl = this.acl;

        try {
            ifaces = this.config.get_interfaces ();
        } catch (GLib.Error err) {
        }

        if (ifaces == null ||
            context.interface in ifaces ||
            context.network in ifaces ||
            context.address.to_string () in ifaces) {
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
            context.active = false;
        }
    }

    private void on_context_unavailable (GUPnP.ContextManager manager,
                                         GUPnP.Context        context) {
        debug ("Network %s (%s) context now unavailable. IP: %s",
               context.network,
               context.interface,
               context.address.to_string ());

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

    public static int main(string[] args) {
        Environment.set_application_name (_(BuildConfig.PACKAGE_NAME));

        // Required to prevent VA-API decoders from crashing when running inside a
        // X11 session. Does nothing if not on X11.
        X.init_threads ();

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (BuildConfig.GETTEXT_PACKAGE,
                             BuildConfig.LOCALEDIR);
        Intl.bind_textdomain_codeset (BuildConfig.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (BuildConfig.GETTEXT_PACKAGE);

        Rygel.Application app = new Rygel.Application ();

        return app.run (args);
    }
}
