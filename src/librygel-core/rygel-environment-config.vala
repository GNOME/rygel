/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

/**
 * Manages configuration from Environment.
 */
public class Rygel.EnvironmentConfig : GLib.Object, Configuration {
    private static string RYGEL_PREFIX = "RYGEL";
    private static string TITLE_KEY = "TITLE";
    private static string DISABLE_PREFIX = RYGEL_PREFIX + "_DISABLE";
    private static string ENABLED_KEY = "ENABLED";
    private static string INTERFACE_ENV = RYGEL_PREFIX + "_IFACE";
    private static string PORT_ENV = RYGEL_PREFIX + "_PORT";
    private static string TRANSCODING_ENV = DISABLE_PREFIX + "_TRANSCODING";
    private static string DISALLOW_UPLOAD_ENV = DISABLE_PREFIX + "_UPLOAD";
    private static string DISALLOW_DELETION_ENV = DISABLE_PREFIX + "_DELETION";
    private static string LOG_LEVELS_ENV = RYGEL_PREFIX + "_LOG";
    private static string PLUGIN_PATH_ENV = RYGEL_PREFIX + "_PLUGIN_PATH";
    private static string ENGINE_PATH_ENV = RYGEL_PREFIX + "_ENGINE_PATH";
    private static string MEDIA_ENGINE_ENV = RYGEL_PREFIX + "_MEDIA_ENGINE";

    // Our singleton
    private static EnvironmentConfig config;

    public static EnvironmentConfig get_default () {
        if (config == null) {
            config = new EnvironmentConfig ();
        }

        return config;
    }

    public string get_interface () throws GLib.Error {
        return this.get_string_variable (INTERFACE_ENV);
    }

    [CCode (array_length=false, array_null_terminated = true)]
    public string[] get_interfaces () throws GLib.Error {
        return this.get_string_variable (INTERFACE_ENV).split (",");
    }

    public int get_port () throws GLib.Error {
        return this.get_int_variable (PORT_ENV, 0, int16.MAX);
    }

    public bool get_transcoding () throws GLib.Error {
        return !this.get_bool_variable (TRANSCODING_ENV);
    }

    public bool get_allow_upload () throws GLib.Error {
        return !this.get_bool_variable (DISALLOW_UPLOAD_ENV);
    }

    public bool get_allow_deletion () throws GLib.Error {
        return !this.get_bool_variable (DISALLOW_DELETION_ENV);
    }

    public string get_log_levels () throws GLib.Error {
        return this.get_string_variable (LOG_LEVELS_ENV);
    }

    public string get_plugin_path () throws GLib.Error {
        return this.get_string_variable (PLUGIN_PATH_ENV);
    }

    public string get_engine_path () throws GLib.Error {
        return this.get_string_variable (ENGINE_PATH_ENV);
    }

    public string get_media_engine () throws GLib.Error {
        return this.get_string_variable (MEDIA_ENGINE_ENV);
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

    public bool get_enabled (string section) throws GLib.Error {
        return get_bool (section, ENABLED_KEY);
    }

    public string get_title (string section) throws GLib.Error {
        return this.get_string (section, TITLE_KEY);
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        return this.get_string_variable (RYGEL_PREFIX + "_" +
                                         section.up () + "_"  +
                                         key.up ().replace ("-", "_"));
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        var str = this.get_string (section, key);
        var value = new ArrayList<string> ();
        foreach (var token in str.split (",", -1)) {
            value.add (token);
        }

        return value;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        return this.get_int_variable (RYGEL_PREFIX + "_" +
                                      section.up () + "_"  +
                                      key.up ().replace ("-","_"),
                                      min,
                                      max);
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        var str = this.get_string (section, key);
        var value = new ArrayList<int> ();
        foreach (var token in str.split (",", -1)) {
            value.add (int.parse (token));
        }

        return value;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        return this.get_bool_variable (RYGEL_PREFIX + "_" +
                                       section.up () + "_"  +
                                       key.up ().replace ("-","_"));
    }

    private string get_string_variable (string variable) throws GLib.Error {
        var str = Environment.get_variable (variable);
        if (str == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return str;
    }

    private int get_int_variable (string variable,
                                  int    min,
                                  int    max) throws GLib.Error {
        var val = Environment.get_variable (variable);
        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return int.parse (val).clamp (min, max);
    }

    private bool get_bool_variable (string variable) throws GLib.Error {
        var enabled = Environment.get_variable (variable);
        if (enabled == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return true;
    }
}
