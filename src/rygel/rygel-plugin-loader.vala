/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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
using GUPnP;
using Gee;

/**
 * Responsible for plugin loading. Probes for shared library files in a specific
 * directry and tries to grab a function with a specific name and signature,
 * calls it. The loaded module can then add plugins to Rygel by calling the
 * add_plugin method.
 */
public class Rygel.PluginLoader : Object {
    private delegate void ModuleInitFunc (PluginLoader loader);

    private HashMap<string,Plugin> plugin_hash;

    // Signals
    public signal void plugin_available (Plugin plugin);

    public PluginLoader () {
        this.plugin_hash = new HashMap<string,Plugin> (str_hash, str_equal);
    }

    // Plugin loading functions
    public void load_plugins () {
        assert (Module.supported());

        File dir = File.new_for_path (BuildConfig.PLUGIN_DIR);
        assert (dir != null && is_dir (dir));

        this.load_modules_from_dir (dir);
    }

    public void add_plugin (Plugin plugin) {
        this.plugin_hash.set (plugin.name, plugin);

        debug ("New plugin '%s' available", plugin.name);
        this.plugin_available (plugin);
    }

    public Plugin? get_plugin_by_name (string name) {
        return this.plugin_hash.get (name);
    }

    public Collection<Plugin> list_plugins () {
        return this.plugin_hash.get_values ();
    }

    private void load_modules_from_dir (File dir) {
        string attributes = FILE_ATTRIBUTE_STANDARD_NAME + "," +
                            FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                            FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;

        dir.enumerate_children_async (attributes,
                                      FileQueryInfoFlags.NONE,
                                      Priority.DEFAULT,
                                      null,
                                      on_children_enumerated);
    }

    private void on_children_enumerated (GLib.Object      source_object,
                                         GLib.AsyncResult res) {
        File dir = (File) source_object;
        FileEnumerator enumerator;

        try {
            enumerator = dir.enumerate_children_finish (res);
        } catch (Error error) {
            critical ("Error listing contents of directory '%s': %s\n",
                      dir.get_path (),
                      error.message);

            return;
        }

        enumerator.next_files_async (int.MAX,
                                     Priority.DEFAULT,
                                     null,
                                     on_next_files_enumerated);
    }

    private void on_next_files_enumerated (GLib.Object      source_object,
                                           GLib.AsyncResult res) {
        FileEnumerator enumerator = (FileEnumerator) source_object;
        File dir = (File) enumerator.get_container ();

        GLib.List<FileInfo> infos;
        try {
            infos = enumerator.next_files_finish (res);
        } catch (Error error) {
            critical ("Error listing contents of directory '%s': %s\n",
                      dir.get_path (),
                      error.message);

            return;
        }

        foreach (var info in infos) {
            string file_name = info.get_name ();
            string file_path = Path.build_filename (dir.get_path (), file_name);

            File file = File.new_for_path (file_path);
            FileType file_type = info.get_file_type ();
            string content_type = info.get_content_type ();
            weak string mime = g_content_type_get_mime_type (content_type);

            if (file_type == FileType.DIRECTORY) {
                // Recurse into directories
                this.load_modules_from_dir (file);
            } else if (mime == "application/x-sharedlib") {
                // Seems like we found a module
                this.load_module_from_file (file_path);
            }
        }
    }

    private void load_module_from_file (string file_path) {
        Module module = Module.open (file_path, ModuleFlags.BIND_LOCAL);
        if (module == null) {
            warning ("Failed to load module from path '%s' : %s\n",
                     file_path,
                     Module.error ());

            return;
        }

        void* function;

        if (!module.symbol("module_init", out function)) {
            warning ("Failed to find entry point function 'module_init'" +
                     " in module loaded from path '%s': %s\n",
                     file_path,
                     Module.error ());

            return;
        }

        ModuleInitFunc module_init = (ModuleInitFunc) function;
        assert (module_init != null);

        // We don't want our modules to ever unload
        module.make_resident ();

        module_init (this);

        debug ("Loaded module source: '%s'\n", module.name());
    }

    private static bool is_dir (File file) {
        FileInfo file_info;

        try {
            file_info = file.query_info (FILE_ATTRIBUTE_STANDARD_TYPE,
                                         FileQueryInfoFlags.NONE,
                                         null);
        } catch (Error error) {
            critical ("Failed to query content type for '%s'\n",
                      file.get_path ());

            return false;
        }

        return file_info.get_file_type () == FileType.DIRECTORY;
    }
}

