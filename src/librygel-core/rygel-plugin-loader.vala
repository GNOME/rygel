/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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

using GUPnP;
using Gee;

/**
 * This class is responsible for plugin loading.
 *
 * It probes for shared library files in a specific directory, tries to 
 * find a module_init() function with this signature:
 * ``void module_init (RygelPluginLoader* loader);``
 *
 * It then calls that function, passing a pointer to itself. The loaded
 * module can then add plugins to Rygel by calling the
 * rygel_plugin_loader_add_plugin() function.
 */
public class Rygel.PluginLoader : RecursiveModuleLoader {
    private delegate void ModuleInitFunc (PluginLoader loader);

    private HashMap<string,Plugin> plugin_hash;
    private HashSet<string>        loaded_modules;

    // Signals
    public signal void plugin_available (Plugin plugin);

    public PluginLoader () {
        Object (base_path: get_config_path ());
    }

    public override void constructed () {
        base.constructed ();

        if (this.base_path == null) {
            this.base_path = get_config_path ();
        }
        this.plugin_hash = new HashMap<string,Plugin> ();
        this.loaded_modules = new HashSet<string> ();
    }

    /**
     * Checks if a plugin is disabled by the user
     *
     * @param name the name of plugin to check for.
     *
     * @return true if plugin is disabled, false if not.
     */
    public bool plugin_disabled (string name) {
        var enabled = true;
        try {
            var config = MetaConfig.get_default ();
            enabled = config.get_enabled (name);
        } catch (GLib.Error err) {}

        return !enabled;
    }

    public void add_plugin (Plugin plugin) {
        message (_("New plugin '%s' available"), plugin.name);
        this.plugin_hash.set (plugin.name, plugin);
        this.plugin_available (plugin);
    }

    public Plugin? get_plugin_by_name (string name) {
        return this.plugin_hash.get (name);
    }

    public Collection<Plugin> list_plugins () {
        return this.plugin_hash.values;
    }

    protected override bool load_module_from_file (File module_file) {
        if (module_file.get_basename () in this.loaded_modules) {
            warning (_("A module named %s is already loaded"),
                     module_file.get_basename ());

            return true;
        }

        Module module = Module.open (module_file.get_path (),
                                     ModuleFlags.BIND_LOCAL);
        if (module == null) {
            warning (_("Failed to load module from path '%s': %s"),
                     module_file.get_path (),
                     Module.error ());

            return true;
        }

        void* function;

        if (!module.symbol("module_init", out function)) {
            warning (_("Failed to find entry point function '%s' in '%s': %s"),
                     "module_init",
                     module_file.get_path (),
                     Module.error ());

            return true;
        }

        unowned ModuleInitFunc module_init = (ModuleInitFunc) function;
        assert (module_init != null);
        this.loaded_modules.add (module_file.get_basename ());

        // We don't want our modules to ever unload
        module.make_resident ();

        module_init (this);

        debug ("Loaded module source: '%s'", module.name());

        return true;
    }

    protected override bool load_module_from_info (PluginInformation info) {
        if (this.plugin_disabled (info.name)) {
            debug ("Module '%s' disabled by user. Ignoring…",
                   info.name);

            return true;
        }

        var module_file = File.new_for_path (info.module_path);

        return this.load_module_from_file (module_file);
    }

    private static string get_config_path () {
        var path = BuildConfig.PLUGIN_DIR;
        try {
            var config = MetaConfig.get_default ();
            path = config.get_plugin_path ();
        } catch (Error error) { }

        return path;
    }
}
