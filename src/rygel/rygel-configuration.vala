/*
 * Copyright (C) 2008,2009 Nokia Corporation, all rights reserved.
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

using GConf;
using CStuff;

/**
 * Reads the user configuration for Rygel.
 */
public class Rygel.Configuration : GLib.Object {
    protected static const string ROOT_GCONF_PATH = "/apps/rygel/";
    protected static const string IP_KEY = "host-ip";
    protected static const string PORT_KEY = "port";
    protected static const string ENABLED_KEY = "enabled";
    protected static const string TITLE_KEY = "title";
    protected static const string TRANSCODING_KEY = "enable-transcoding";
    protected static const string MP3_TRANSCODER_KEY = "enable-mp3-transcoder";
    protected static const string MP2TS_TRANSCODER_KEY =
                                                    "enable-mp2ts-transcoder";
    protected static const string LPCM_TRANSCODER_KEY =
                                                    "enable-lpcm-transcoder";

    // Our singleton
    private static Configuration config;

    protected GConf.Client gconf;

    private string _host_ip;
    public string host_ip {
        get {
            _host_ip = this.get_string ("general", IP_KEY, null);
            return _host_ip;
        }
        set {
            this.set_string ("general", IP_KEY, value);
        }
    }

    public int port {
        get {
            return this.get_int ("general",
                                 PORT_KEY,
                                 uint16.MIN,
                                 uint16.MAX,
                                 0);
        }
        set {
            this.set_int ("general", PORT_KEY, value);
        }
    }

    public bool transcoding {
        get {
            return this.get_bool ("general", TRANSCODING_KEY, true);
        }
        set {
            this.set_bool ("general", TRANSCODING_KEY, value);
        }
    }

    public bool mp3_transcoder {
        get {
            return this.get_bool ("general", MP3_TRANSCODER_KEY, true);
        }
        set {
            this.set_bool ("general", MP3_TRANSCODER_KEY, value);
        }
    }

    public bool mp2ts_transcoder {
        get {
            return this.get_bool ("general", MP2TS_TRANSCODER_KEY, true);
        }
        set {
            this.set_bool ("general", MP2TS_TRANSCODER_KEY, value);
        }
    }

    public bool lpcm_transcoder {
        get {
            return this.get_bool ("general", LPCM_TRANSCODER_KEY, true);
        }
        set {
            this.set_bool ("general", LPCM_TRANSCODER_KEY, value);
        }
    }

    public static Configuration get_default () {
        if (config == null) {
            config = new Configuration ();
        }

        return config;
    }

    public Configuration () {
        this.gconf = GConf.Client.get_default ();
    }

    public bool get_enabled (string section) {
        return this.get_bool (section, ENABLED_KEY, true);
    }

    public string get_title (string section, string default_title) {
        return this.get_string (section, TITLE_KEY, default_title);
    }

    public string? get_string (string  section,
                               string  key,
                               string? default_value) {
        string val;
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            val = this.gconf.get_string (path);
        } catch (GLib.Error error) {
            val = null;
        }

        if (val == null || val == "") {
            val = default_value;
        }

        return val;
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key) {
        var str_list = new Gee.ArrayList<string> ();
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            unowned SList<string> strings = this.gconf.get_list (
                                                        path,
                                                        GConf.ValueType.STRING);
            if (strings != null) {
                foreach (var str in strings) {
                    str_list.add (str);
                }
            }
        } catch (GLib.Error error) {
            warning ("Failed to get value for key: %s\n", path);
        }

        return str_list;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max,
                        int    default_value) {
        int val;
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            val = this.gconf.get_int (path);
        } catch (GLib.Error error) {
            val = default_value;
        }

        if (val < min || val > max) {
            val = default_value;
        }

        return val;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key) {
        var int_list = new Gee.ArrayList<int> ();
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            unowned SList<int> ints = this.gconf.get_list (
                                                    path,
                                                    GConf.ValueType.INT);
            if (ints != null) {
                foreach (var num in ints) {
                    int_list.add (num);
                }
            }
        } catch (GLib.Error error) {
            warning ("Failed to get value for key: %s", path);
        }

        return int_list;
    }

    public bool get_bool (string section,
                          string key,
                          bool   default_value) {
        bool val;
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            unowned GConf.Value value = this.gconf.get (path);
            if (value != null) {
                val = value.get_bool ();
            } else {
                val = default_value;
            }
        } catch (GLib.Error error) {
            val = default_value;
        }

        return val;
    }

    public void set_string (string section,
                            string key,
                            string value) {
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            this.gconf.set_string (path, value);
        } catch (GLib.Error error) {
            // No big deal
        }
    }

    public void set_string_list (string                section,
                                 string                key,
                                 Gee.ArrayList<string> str_list) {
        var path = ROOT_GCONF_PATH + section + "/" + key;

        // GConf requires us to provide it GLib.SList
        SList<string> slist = null;

        foreach (var str in str_list) {
            if (str != "") {
                slist.append (str);
            }
        }

        try {
            this.gconf.set_list (path, GConf.ValueType.STRING, slist);
        } catch (GLib.Error error) {
            // No big deal
        }
    }

    public void set_int (string section,
                         string key,
                         int    value) {
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            this.gconf.set_int (path, value);
        } catch (GLib.Error error) {
            // No big deal
        }
    }

    public void set_bool (string section,
                          string key,
                          bool   value) {
        var path = ROOT_GCONF_PATH + section + "/" + key;

        try {
            this.gconf.set_bool (path, value);
        } catch (GLib.Error error) {
            // No big deal
        }
    }
}

