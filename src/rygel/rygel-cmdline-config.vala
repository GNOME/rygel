/*
 * Copyright (C) 2008,2009 Nokia Corporation.
 * Copyright (C) 2008,2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

public errordomain Rygel.CmdlineConfigError {
    VERSION_ONLY
}

/**
 * Manages configuration from Commandline arguments.
 */
public class Rygel.CmdlineConfig : GLib.Object, Configuration {
    private static string iface;
    private static int port;

    private static bool no_upnp;
    private static bool no_transcoding;

    private static bool disallow_upload;
    private static bool disallow_deletion;

    private static string log_levels;

    private static string plugin_path;
    private static string engine_path;

    private static bool version;

    private static string config_file;

    [CCode (array_length = false, array_null_terminated = true)]
    [NoArrayLength]
    private static string[] disabled_plugins;
    [CCode (array_length = false, array_null_terminated = true)]
    [NoArrayLength]
    private static string[] plugin_titles;
    [CCode (array_length = false, array_null_terminated = true)]
    [NoArrayLength]
    private static string[] plugin_options;

    // Our singleton
    private static CmdlineConfig config;

    // Command-line options
	const OptionEntry[] OPTIONS = {
        { "version", 0, 0, OptionArg.NONE, ref version,
          "Display version number", null },
        { "network-interface", 'n', 0, OptionArg.STRING, ref iface,
          "Network Interface", "INTERFACE" },
        { "port", 'p', 0, OptionArg.INT, ref port,
          "Port", "PORT" },
        { "disable-transcoding", 't', 0, OptionArg.NONE, ref no_transcoding,
          "Disable transcoding", null },
        { "disallow-upload", 'U', 0, OptionArg.NONE,
          ref disallow_upload, "Disallow upload", null },
        { "disallow-deletion", 'D', 0, OptionArg.NONE,
          ref disallow_deletion, "Disallow deletion", null },
        { "log-level", 'g', 0, OptionArg.STRING, ref log_levels,
          "Comma-separated list of domain:level pairs to specify log level " +
          "thresholds for individual domains. domain could be either " +
          "'rygel', name of a plugin or '*' for all domains. " +
          " Allowed levels are: " +
          "0=critical,2=error,3=warning,4=message/info,5=debug.",
          "DOMAIN1:LEVEL1[,DOMAIN2:LEVEL2,..]" },
        { "plugin-path", 'u', 0, OptionArg.STRING, ref plugin_path,
          "Plugin Path", "PLUGIN_PATH" },
        { "engine-path", 'e', 0, OptionArg.STRING, ref engine_path,
          "Engine Path", "ENGINE_PATH" },
        { "disable-plugin", 'd', 0, OptionArg.STRING_ARRAY,
          ref disabled_plugins,
          "Disable plugin", "PluginName" },
        { "title", 'i', 0, OptionArg.STRING_ARRAY, ref plugin_titles,
          "Set plugin titles", "PluginName:TITLE" },
        { "plugin-option", 'o', 0, OptionArg.STRING_ARRAY, ref plugin_options,
          "Set plugin options", "PluginName:OPTION:VALUE1[,VALUE2,..]" },
        { "disable-upnp", 'P', 0, OptionArg.NONE, ref no_upnp,
          "Disable UPnP (streaming-only)", null },
        { "config", 'c', 0, OptionArg.FILENAME, ref config_file,
          "Use configuration file instead of user configuration", null },
        { null }
	};

    public static CmdlineConfig get_default () {
        if (config == null) {
            config = new CmdlineConfig ();
        }

        return config;
    }

    public static void parse_args (ref unowned string[] args)
                                   throws CmdlineConfigError.VERSION_ONLY,
                                          OptionError {
        var parameter_string = "- " + BuildConfig.PACKAGE_NAME;
        var opt_context = new OptionContext (parameter_string);
        opt_context.set_help_enabled (true);
        opt_context.set_ignore_unknown_options (true);
        opt_context.add_main_entries (OPTIONS, null);

        try {
            opt_context.parse (ref args);
        } catch (OptionError.BAD_VALUE err) {
            stdout.printf (opt_context.get_help (true, null));

            throw new CmdlineConfigError.VERSION_ONLY ("");
        }

        if (version) {
            stdout.printf ("%s\n", BuildConfig.PACKAGE_STRING);

            throw new CmdlineConfigError.VERSION_ONLY ("");
        }
    }

    public bool get_upnp_enabled () throws GLib.Error {
        if (!no_upnp) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public string get_interface () throws GLib.Error {
        if (iface == null) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return iface;
    }

    public int get_port () throws GLib.Error {
        if (port <= 0) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return port;
    }

    public bool get_transcoding () throws GLib.Error {
        if (!no_transcoding) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_allow_upload () throws GLib.Error {
        if (!disallow_upload) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_allow_deletion () throws GLib.Error {
        if (!disallow_deletion) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public string get_log_levels () throws GLib.Error {
        if (log_levels == null) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return log_levels;
    }

    public string get_plugin_path () throws GLib.Error {
        if (plugin_path == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return plugin_path;
    }

    public string get_engine_path () throws GLib.Error {
        if (engine_path == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return plugin_path;
    }

    public string get_media_engine () throws GLib.Error {
        // We don't support setting this via commandline
        throw new ConfigurationError.NO_VALUE_SET ("No value available");
    }

    public bool get_enabled (string section) throws GLib.Error {
        var disabled = false;
        foreach (var plugin in disabled_plugins) {
            if (plugin == section) {
                disabled = true;
                break;
            }
        }

        if (disabled) {
            return false;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }

    public string get_title (string section) throws GLib.Error {
        string title = null;
        foreach (var plugin_title in plugin_titles) {
            var tokens = plugin_title.split (":", 2);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[0] == section) {
                title = tokens[1];
                break;
            }
        }

        if (title != null) {
            return title;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }

    public string get_config_file () throws GLib.Error {
        if (config_file == null) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return config_file;
    }

    public string get_video_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string get_music_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string get_picture_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    // Dynamic options
    // FIXME: How to handle them?
    public string get_string (string section,
                              string key) throws GLib.Error {
        string value = null;
        foreach (var option in plugin_options) {
            var tokens = option.split (":", 3);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[2] != null &&
                tokens[0] == section &&
                tokens[1] == key) {
                value = tokens[2];
                break;
            }
        }

        if (value != null) {
            return value;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        ArrayList<string> value = null;
        foreach (var option in plugin_options) {
            var tokens = option.split (":", 3);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[2] != null &&
                tokens[0] == section &&
                tokens[1] == key) {
                value = new ArrayList<string> ();
                foreach (var val_token in tokens[2].split (",", -1)) {
                    value.add (val_token);
                }
                break;
            }
        }

        if (value != null) {
            return value;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int value = 0;
        bool value_set = false;
        foreach (var option in plugin_options) {
            var tokens = option.split (":", 3);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[2] != null &&
                tokens[0] == section &&
                tokens[1] == key) {
                value = int.parse (tokens[2]);
                if (value >= min && value <= max) {
                    value_set = true;
                }
                break;
            }
        }

        if (value_set) {
            return value;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        ArrayList<int> value = null;
        foreach (var option in plugin_options) {
            var tokens = option.split (":", 3);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[2] != null &&
                tokens[0] == section &&
                tokens[1] == key) {
                value = new ArrayList<int> ();
                foreach (var val_token in tokens[2].split (",", -1)) {
                    value.add (int.parse (val_token));
                }
                break;
            }
        }

        if (value != null) {
            return value;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        bool value = false;
        bool value_set = false;
        foreach (var option in plugin_options) {
            var tokens = option.split (":", 3);
            if (tokens[0] != null &&
                tokens[1] != null &&
                tokens[2] != null &&
                tokens[0] == section &&
                tokens[1] == key) {
                value = bool.parse (tokens[2]);
                value_set = true;
                break;
            }
        }

        if (value_set) {
            return value;
        } else {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }
    }
}
