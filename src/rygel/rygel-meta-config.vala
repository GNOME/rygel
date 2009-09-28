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
using CStuff;

/**
 * Manages all the configuration sources for Rygel.
 *
 * Abstracts Rygel and it's plugins from Configuration implementations. It keeps
 * all real configuration sources in a list and returns the value provided by
 * the first one. If none of them provides the value, it emits an error.
 */
public class Rygel.MetaConfig : GLib.Object, Configuration {
    // Our singleton
    private static MetaConfig meta_config;

    private ArrayList<Configuration> configs;

    public static MetaConfig get_default () {
        if (meta_config == null) {
            meta_config = new MetaConfig ();
        }

        return meta_config;
    }

    public MetaConfig () {
        this.configs = new ArrayList<Configuration> ();

        this.configs.add (CmdlineConfig.get_default ());
        try {
            var user_config = UserConfig.get_default ();
            this.configs.add (user_config);
        } catch (Error err) {
            warning ("Failed to load user configuration: %s", err.message);
        }
    }

    public bool get_upnp_enabled () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_upnp_enabled ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public string get_interface () throws GLib.Error {
        string val = null;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_interface ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public int get_port () throws GLib.Error {
        int val = 0;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_port ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public bool get_transcoding () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_transcoding ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public bool get_mp3_transcoder () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_mp3_transcoder ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public bool get_mp2ts_transcoder () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_mp2ts_transcoder ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public bool get_lpcm_transcoder () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_lpcm_transcoder ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public LogLevel get_log_level () throws GLib.Error {
        LogLevel val = LogLevel.DEFAULT;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_log_level ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET ("No value available");
        }

        return val;
    }

    public bool get_enabled (string section) throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_enabled (section);
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/enabled'",
                                        section);
        }

        return val;
    }

    public string get_title (string section) throws GLib.Error {
        string val = null;

        foreach (var config in this.configs) {
            try {
                val = config.get_title (section);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/enabled'",
                                        section);
        }

        return val;
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        string val = null;

        foreach (var config in this.configs) {
            try {
                val = config.get_string (section, key);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/%s'",
                                        section,
                                        key);
        }

        return val;
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        Gee.ArrayList<string> val = null;

        foreach (var config in this.configs) {
            try {
                val = config.get_string_list (section, key);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/%s'",
                                        section,
                                        key);
        }

        return val;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int val = 0;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_int (section, key, min, max);
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/%s'",
                                        section,
                                        key);
        }

        return val;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        Gee.ArrayList<int> val = null;

        foreach (var config in this.configs) {
            try {
                val = config.get_int_list (section, key);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/%s'",
                                        section,
                                        key);
        }

        return val;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        bool val = false;
        bool unavailable = true;

        foreach (var config in this.configs) {
            try {
                val = config.get_bool (section, key);
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s/%s'",
                                        section,
                                        key);
        }

        return val;
    }
}

