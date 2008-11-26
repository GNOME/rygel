/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using CStuff;
using GUPnP;

/**
 * Responsible for plugin loading. Probes for shared library files in a specific
 * directry and tries to grab a function with a specific name and signature,
 * calls it and expects a Plugin instance in return.
 */
public class Rygel.PluginLoader : Object {
    /* We need to keep the modules somewhere */
    private List<Module> modules;

    private delegate Plugin LoadPluginFunc ();

    // Signals
    public signal void plugin_available (Plugin plugin);

    /* Pubic methods */
    public PluginLoader () {
        this.modules = new List<Module> ();
    }

    // Plugin loading functions
    public void load_plugins () {
        assert (Module.supported());

        File dir = File.new_for_path (BuildConfig.PLUGIN_DIR);
        assert (dir != null && is_dir (dir));

        this.load_plugins_from_dir (dir);
    }

    private void load_plugins_from_dir (File dir) {
        FileEnumerator enumerator;

        try {
            string attributes = FILE_ATTRIBUTE_STANDARD_NAME + "," +
                                FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                                FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE;
            enumerator = dir.enumerate_children (attributes,
                                                 FileQueryInfoFlags.NONE,
                                                 null);
        } catch (Error error) {
            critical ("Error listing contents of directory '%s': %s\n",
                      dir.get_path (),
                      error.message);

            return;
        }

        FileInfo info;

        while ((info = enumerator.next_file (null)) != null) {
            string file_name = info.get_name ();
            string file_path = Path.build_filename (dir.get_path (),
                                                        file_name);
            File file = File.new_for_path (file_path);
            FileType file_type = info.get_file_type ();
            string content_type = info.get_content_type ();
            weak string mime = g_content_type_get_mime_type (content_type);

            if (file_type == FileType.DIRECTORY) {
                // Recurse into directories
                this.load_plugins_from_dir (file);
            } else if (mime == "application/x-sharedlib") {
                // Seems like we found a plugin
                this.load_plugin_from_file (file_path);
            }
        }
    }

    private void load_plugin_from_file (string file_path) {
        Module module = Module.open (file_path, ModuleFlags.BIND_LOCAL);
        if (module == null) {
            debug ("Failed to load plugin from path: '%s'\n", file_path);

            return;
        }

        void* function;

        module.symbol("load_plugin", out function);

        LoadPluginFunc load_plugin = (LoadPluginFunc) function;
        if (load_plugin == null) {
            warning ("Failed to load plugin from path: '%s'\n", file_path);

            return;
        }

        debug ("Loaded plugin: '%s'\n", module.name());

        Plugin plugin = load_plugin ();
        if (plugin != null) {
            this.plugin_available (plugin);
            this.modules.append (#module);
        }
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

