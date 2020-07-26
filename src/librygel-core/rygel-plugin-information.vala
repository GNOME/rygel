/*
 * Copyright (C) 2013 Jens Georg.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * Parse plugin sidecar file and provide path to the module.
 *
 * Sidecar files are keyfiles, loosely compatible with the files used by
 * libpeas.
 *
 * A minimal file for the plugin librygel-sompelugin.so looks like this:
 *
 * [Plugin]
 * Name = SomeNameForThePlugin
 * Module = someplugin
 *
 * Name must not contain any whitespaces.
 */
public class Rygel.PluginInformation : Object {
    /// Full path to the loadable module file
    public string module_path { get; construct; }

    /// Name of this module
    public string name { get; construct; }

    /// Name of other plugins this plugin conflicts with
    public GenericSet<string> conflicts { get; construct; }

    /// Whether the module was loaded or not
    public bool module_loaded { get; set; default = false; }

    private PluginInformation (string module_path,
                               string name,
                               GenericSet<string> conflicts) {
        Object (module_path: module_path, name : name, conflicts : conflicts);
    }

    /**
     * Factory method to create a #RygelPluginInformation from #GFile.
     *
     * @param file a #GFile pointing to the sidecar file
     * @return A new instance of #RygelPluginInformation
     */
    public static PluginInformation new_from_file (File file) throws Error {
        var keyfile = new KeyFile ();
        keyfile.load_from_file (file.get_path (), KeyFileFlags.NONE);
        if (!keyfile.has_group ("Plugin")) {
            throw new KeyFileError.GROUP_NOT_FOUND
                                        (_("[Plugin] group not found"));
        }

        var name = keyfile.get_string ("Plugin", "Name");
        var module = keyfile.get_string ("Plugin", "Module");

        var module_dir = file.get_parent ();
        var module_file = module_dir.get_child ("librygel-%s.%s".printf (
                                                module,
                                                Module.SUFFIX));

        if (!module_file.query_exists ()) {
            throw new FileError.EXIST (_("Plugin module %s does not exist"),
                                       module_file.get_path ());
        }

        var conflicts = new GenericSet<string>(str_hash, str_equal);
        try {
            foreach (var other_name in keyfile.get_string_list ("Plugin", "Conflicts")) {
                other_name.strip();
                conflicts.add (other_name);
            }
        } catch (KeyFileError err) {
            // Do nothing
        }

        return new PluginInformation (module_file.get_path (), name, conflicts);
    }
}
