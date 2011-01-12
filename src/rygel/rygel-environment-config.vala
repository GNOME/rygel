/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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

/**
 * Manages configuration from Environment.
 */
internal class Rygel.EnvironmentConfig : GLib.Object, Configuration {
    private static string RYGEL_PREFIX = "RYGEL";
    private static string TITLE_KEY = RYGEL_PREFIX + "_TITLE";
    private static string ENABLED_KEY = "ENABLED";
    private static string INTERFACE_ENV = RYGEL_PREFIX + "_IFACE";
    private static string PORT_ENV = RYGEL_PREFIX + "_PORT";
    private static string DISABLE_UPNP_ENV = RYGEL_PREFIX + "_DISABLE_UPNP";
    private static string TRANSCODING_ENV = RYGEL_PREFIX + "_TRANSCODING";
    private static string MP3_TRANSCODING_ENV = RYGEL_PREFIX + "_MP3_TRANS";
    private static string LPCM_TRANSCODING_ENV = RYGEL_PREFIX + "_LPCM_TRANS";
    private static string MP2TS_TRANSCODING_ENV = RYGEL_PREFIX + "_MP2TS_TRANS";
    private static string WMV_TRANSCODING_ENV = RYGEL_PREFIX + "_WMV_TRANS";
    private static string ALLOW_UPLOAD_ENV = RYGEL_PREFIX + "_ALLOW_UPLOAD";
    private static string ALLOW_DELETION_ENV = RYGEL_PREFIX + "_ALLOW_DELETION";
    private static string LOG_LEVEL_ENV = RYGEL_PREFIX + "_LOG";
    private static string PLUGIN_PATH_ENV = RYGEL_PREFIX + "_PLUGIN_PATH";

    // Our singleton
    private static EnvironmentConfig config;

    public static EnvironmentConfig get_default () {
        if (config == null) {
            config = new EnvironmentConfig ();
        }

        return config;
    }

    public bool get_upnp_enabled () throws GLib.Error {
        return !this.get_bool_variable (DISABLE_UPNP_ENV);
    }

    public string get_interface () throws GLib.Error {
        return this.get_string_variable (INTERFACE_ENV);
    }

    public int get_port () throws GLib.Error {
        return this.get_int_variable (PORT_ENV, 0, int16.MAX);
    }

    public bool get_transcoding () throws GLib.Error {
        return this.get_bool_variable (TRANSCODING_ENV);
    }

    public bool get_mp3_transcoder () throws GLib.Error {
        return this.get_bool_variable (MP3_TRANSCODING_ENV);
    }

    public bool get_mp2ts_transcoder () throws GLib.Error {
        return this.get_bool_variable (MP2TS_TRANSCODING_ENV);
    }

    public bool get_wmv_transcoder () throws GLib.Error {
        return this.get_bool_variable (WMV_TRANSCODING_ENV);
    }

    public bool get_lpcm_transcoder () throws GLib.Error {
        return this.get_bool_variable (LPCM_TRANSCODING_ENV);
    }

    public bool get_allow_upload () throws GLib.Error {
        return this.get_bool_variable (ALLOW_UPLOAD_ENV);
    }

    public bool get_allow_deletion () throws GLib.Error {
        return this.get_bool_variable (ALLOW_DELETION_ENV);
    }

    public LogLevel get_log_level () throws GLib.Error {
        return (LogLevel) this.get_int_variable (LOG_LEVEL_ENV,
                                                LogLevel.CRITICAL,
                                                LogLevel.DEBUG);
    }

    public string get_plugin_path () throws GLib.Error {
        return this.get_string_variable (PLUGIN_PATH_ENV);
    }

    public bool get_enabled (string section) throws GLib.Error {
        return get_bool (section, ENABLED_KEY);
    }

    public string get_title (string section) throws GLib.Error {
        return this.get_string (RYGEL_PREFIX + "_" + section, TITLE_KEY);
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        return this.get_string_variable (RYGEL_PREFIX + "_" +
                                         section.up () + "_"  +
                                         key);
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
                                      section.up () + "_"  + key,
                                      min,
                                      max);
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        var str = this.get_string (section, key);
        var value = new ArrayList<int> ();
        foreach (var token in str.split (",", -1)) {
            value.add (token.to_int ());
        }

        return value;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        return this.get_bool_variable (RYGEL_PREFIX + "_" +
                                       section.up () + "_"  +
                                       key);
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

        return val.to_int ().clamp (min, max);
    }

    private bool get_bool_variable (string variable) throws GLib.Error {
        var enabled = Environment.get_variable (variable);
        if (enabled == null) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return enabled.to_bool ();
    }
}

