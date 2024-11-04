/*
 * Copyright (C) 2008,2009 Nokia Corporation.
 * Copyright (C) 2008,2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2014 Jens Georg <mail@jensge.org>
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *                    <mail@jensge.org>
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

using Gee;

public errordomain Rygel.CmdlineConfigError {
    VERSION_ONLY
}

/**
 * Manages configuration from Commandline arguments.
 */
public class Rygel.CmdlineConfig : GLib.Object, Configuration {
    private VariantDict options;

    // Our singleton
    private static CmdlineConfig config;

    // Command-line options
    public const OptionEntry[] OPTIONS = {
        { "version", 'v', 0, OptionArg.NONE, null,
          N_("Display version number"), null },
        { "network-interface", 'n', 0, OptionArg.STRING_ARRAY, null,
          N_("Network Interfaces"), "INTERFACE" },
        { "port", 'p', 0, OptionArg.INT, null,
          N_("Port"), "PORT" },
        { "disable-transcoding", 't', 0, OptionArg.NONE, null,
          N_("Disable transcoding"), null },
        { "disallow-upload", 'U', 0, OptionArg.NONE,
          null, N_("Disallow upload"), null },
        { "disallow-deletion", 'D', 0, OptionArg.NONE,
          null, N_ ("Disallow deletion"), null },
        { "log-level", 'g', 0, OptionArg.STRING, null,
          N_ ("Comma-separated list of domain:level pairs. See rygel(1) for details") },
        { "plugin-path", 'u', 0, OptionArg.STRING, null,
          N_ ("Plugin Path"), "PLUGIN_PATH" },
        { "engine-path", 'e', 0, OptionArg.STRING, null,
          N_ ("Engine Path"), "ENGINE_PATH" },
        { "disable-plugin", 'd', 0, OptionArg.STRING_ARRAY,
          null,
          N_ ("Disable plugin"), "PluginName" },
        { "title", 'i', 0, OptionArg.STRING_ARRAY, null,
          N_ ("Set plugin titles"), "PluginName:TITLE" },
        { "plugin-option", 'o', 0, OptionArg.STRING_ARRAY, null,
          N_ ("Set plugin options"), "PluginName:OPTION:VALUE1[,VALUE2,..]" },
        { "config", 'c', 0, OptionArg.FILENAME, null,
          N_ ("Use configuration file instead of user configuration"), "FILE" },
        { "shutdown", 's', 0, OptionArg.NONE, null,
          N_ ("Shut down remote Rygel reference"), null },
        { null }
    };

    public static CmdlineConfig get_default () {
        if (config == null) {
            config = new CmdlineConfig ();
        }

        return config;
    }

    public void set_options (VariantDict args) {
        this.options = args;
    }

    public string get_interface () throws GLib.Error {
        return get_interfaces ()[0];
    }

    [CCode (array_length=false, array_null_terminated = true)]
    public string[] get_interfaces () throws GLib.Error {
        string[] ifaces = null;
        if (!this.options.lookup ("network-interface", "^as", out ifaces)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return ifaces;
    }

    public int get_port () throws GLib.Error {
        int port = 0;
        if (!this.options.lookup ("port", "i", out port)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return port;
    }

    public bool get_transcoding () throws GLib.Error {
        bool val;
        if (!this.options.lookup ("disable-transcoding", "b", out val)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_allow_upload () throws GLib.Error {
        bool val;
        if (!this.options.lookup ("disable-transcoding", "b", out val)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_allow_deletion () throws GLib.Error {
        bool val;
        if (!this.options.lookup ("disable-transcoding", "b", out val)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public string get_log_levels () throws GLib.Error {
        unowned string log_levels = null;
        if (!options.lookup ("log-level", "&s", out log_levels)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return log_levels;
    }

    public string get_plugin_path () throws GLib.Error {
        unowned string plugin_path = null;
        if (!options.lookup ("plugin-path", "&s", out plugin_path)) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return plugin_path;
    }

    public string get_engine_path () throws GLib.Error {
        unowned string engine_path = null;
        if (!options.lookup ("engine-path", "&s", out engine_path)) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return engine_path;
    }

    public string get_media_engine () throws GLib.Error {
        // We don't support setting this via commandline
        throw new ConfigurationError.NO_VALUE_SET ("No value available");
    }


    // Work-around to make vala aware of the null-termination
    [CCode (array_length=false, array_null_terminated = true)]
    private string[] get_string_list_from_options (string key) throws GLib.Error {
        string[] disabled_plugins = null;

        if (!options.lookup (key, "^as", out disabled_plugins)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return disabled_plugins;
    }

    public bool get_enabled (string section) throws GLib.Error {
        foreach (var plugin in get_string_list_from_options ("disable-plugin")) {
            print ("Checking %s against %s\n", section, plugin);
            if (section == plugin)
                return false;
        }

        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string get_title (string section) throws GLib.Error {
        var plugin_titles = this.get_string_list_from_options ("plugin-title");

        foreach (var entry in plugin_titles) {
            var tokens = entry.split (":", 2);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[0] == section) {
                return tokens[1];
            }
        }

        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string get_config_file () throws GLib.Error {
        unowned string config_file = null;
        if (!options.lookup ("config", "^ay", out config_file)) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return config_file;
    }

    public string? get_video_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string? get_music_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string? get_picture_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    // Dynamic options
    // FIXME: How to handle them?
    public string get_string (string section,
                              string key) throws GLib.Error {
        var plugin_options = this.get_string_list_from_options ("plugin-option");

        foreach (var option in plugin_options) {
            var tokens = option.split (":", 3);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[2] != null &&
                tokens[0] == section &&
                tokens[1] == key) {
                return tokens[2];
            }
        }

        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        var val = new ArrayList<string> ();
        foreach (var val_token in this.get_string (section, key).split (",", -1)) {
            val.add (val_token);
        }

        return val;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int result;

        if (!int.try_parse (this.get_string (section, key), out result)) {
            throw new ConfigurationError.VALUE_OUT_OF_RANGE (_("No value available"));
        }

        if (result < min || result > max) {
            throw new ConfigurationError.VALUE_OUT_OF_RANGE (_("No value available"));
        }

        return result;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                           throws GLib.Error {
        var val = new ArrayList<int> ();
        foreach (var val_token in this.get_string (section, key).split (",", -1)) {
            int result;
            if (!int.try_parse (val_token, out result)) {
                throw new ConfigurationError.VALUE_OUT_OF_RANGE (_("No value available"));
            }

            val.add (result);
        }

        return val;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        return bool.parse (this.get_string (section, key));
    }
}
