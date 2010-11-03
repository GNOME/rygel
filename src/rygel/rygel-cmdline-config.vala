/*
 * Copyright (C) 2008,2009 Nokia Corporation.
 * Copyright (C) 2008,2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

internal errordomain Rygel.CmdlineConfigError {
    VERSION_ONLY
}

/**
 * Manages configuration from Commandline arguments.
 */
internal class Rygel.CmdlineConfig : GLib.Object, Configuration {
    private static string iface;
    private static int port;

    private static bool no_transcoding;
    private static bool no_mp3_trans;
    private static bool no_mp2ts_trans;
    private static bool no_lpcm_trans;
    private static bool no_wmv_trans;

    private static bool disallow_upload;

    private static LogLevel log_level = LogLevel.INVALID;

    private static string plugin_path;

    private static bool version;

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
	const OptionEntry[] options = {
        { "version", 0, 0, OptionArg.NONE, ref version,
          "Display version number", null },
        { "network-interface", 'n', 0, OptionArg.STRING, ref iface,
          "Network Interface", "INTERFACE" },
        { "port", 'p', 0, OptionArg.INT, ref port,
          "Port", "PORT" },
        { "disable-transcoding", 't', 0, OptionArg.NONE, ref no_transcoding,
          "Disable transcoding", null },
        { "disable-mp3-transcoder", 'm', 0, OptionArg.NONE, ref no_mp3_trans,
          "Disable MP3 transcoder", null },
        { "disable-mp2ts-transcoder", 's', 0, OptionArg.NONE,
          ref no_mp2ts_trans,
          "Disable mpeg2 transport stream transcoder", null },
        { "disable-lpcm-transcoder", 'l', 0, OptionArg.NONE, ref no_lpcm_trans,
          "Disable Linear PCM transcoder", null },
        { "disable-wmv-transcoder", 'w', 0, OptionArg.NONE, ref no_wmv_trans,
          "Disable WMV transcoder", null },
        { "disallow-upload", 'U', 0, OptionArg.NONE,
          ref disallow_upload, "Disallow upload", null },
        { "log-level", 'g', 0, OptionArg.INT, ref log_level,
          "Log level. 1=critical,2=error,3=warning,4=message/info,5=debug",
          "N" },
        { "plugin-path", 'u', 0, OptionArg.STRING, ref plugin_path,
          "Plugin Path", "PLUGIN_PATH" },
        { "disable-plugin", 'd', 0, OptionArg.STRING_ARRAY,
          ref disabled_plugins,
          "Disable plugin", "PluginName" },
        { "title", 'i', 0, OptionArg.STRING_ARRAY, ref plugin_titles,
          "Set plugin titles", "PluginName:TITLE" },
        { "plugin-option", 'o', 0, OptionArg.STRING_ARRAY, ref plugin_options,
          "Set plugin options", "PluginName:OPTION:VALUE1[,VALUE2,..]" },
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
        opt_context.add_main_entries (options, null);
        opt_context.add_group (Gst.init_get_option_group ());
        opt_context.parse (ref args);

		if (version) {
			stdout.printf ("%s\n", BuildConfig.PACKAGE_STRING);
			throw new CmdlineConfigError.VERSION_ONLY ("");
		}
    }

    // Why would someone lauch rygel to kill itself?
    public bool get_upnp_enabled () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
    }

    public string get_interface () throws GLib.Error {
        if (iface == null) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return iface;
    }

    public int get_port () throws GLib.Error {
        if (this.port <= 0) {
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

    public bool get_mp3_transcoder () throws GLib.Error {
        if (!no_mp3_trans) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_mp2ts_transcoder () throws GLib.Error {
        if (!no_mp2ts_trans) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_lpcm_transcoder () throws GLib.Error {
        if (!no_lpcm_trans) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        } else {
            return false;
        }
    }

    public bool get_wmv_transcoder () throws GLib.Error {
        if (!no_wmv_trans) {
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

    public LogLevel get_log_level () throws GLib.Error {
        if (this.log_level == LogLevel.INVALID) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return log_level;
    }

    public string get_plugin_path () throws GLib.Error {
        if (plugin_path == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return plugin_path;
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
                value = tokens[2].to_int ();
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
                    value.add (val_token.to_int ());
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
                value = tokens[2].to_bool ();
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

