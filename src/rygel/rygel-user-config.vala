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
 * Manages the user configuration for Rygel.
 */
public class Rygel.UserConfig : GLib.Object, Configuration {
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

    private const string DBUS_SERVICE = "org.freedesktop.DBus";
    private const string DBUS_PATH = "/org/freedesktop/DBus";
    private const string DBUS_INTERFACE = "org.freedesktop.DBus";

    private const string RYGEL_SERVICE = "org.gnome.Rygel";
    private const string RYGEL_PATH = "/org/gnome/Rygel";
    private const string RYGEL_INTERFACE = "org.gnome.Rygel";

    // Our singleton
    private static UserConfig config;

    protected GConf.Client gconf;

    private dynamic DBus.Object dbus_obj;
    private dynamic DBus.Object rygel_obj;

    public bool upnp_enabled {
        get {
            return this.get_bool ("general", ENABLED_KEY, true);
        }
        set {
            if (value != this.upnp_enabled) {
                this.enable_upnp (value);
            }
        }
    }

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

    public static UserConfig get_default () {
        if (config == null) {
            config = new UserConfig ();
        }

        return config;
    }

    public UserConfig () {
        this.gconf = GConf.Client.get_default ();

        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        // Create proxy to Rygel
        this.rygel_obj = connection.get_object (RYGEL_SERVICE,
                                                RYGEL_PATH,
                                                RYGEL_INTERFACE);
        // and DBus
        this.dbus_obj = connection.get_object (DBUS_SERVICE,
                                               DBUS_PATH,
                                               DBUS_INTERFACE);
    }

    public bool get_enabled (string section) throws GLib.Error {
        return this.get_bool (section, ENABLED_KEY);
    }

    public string get_title (string section) throws GLib.Error {
        return this.get_string (section, TITLE_KEY);
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        string val;
        var path = ROOT_GCONF_PATH + section + "/" + key;

        val = this.gconf.get_string (path);

        if (val == null || val == "") {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s'", key);
        }

        return val;
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        var str_list = new Gee.ArrayList<string> ();
        var path = ROOT_GCONF_PATH + section + "/" + key;

        unowned SList<string> strings = this.gconf.get_list (
                path,
                GConf.ValueType.STRING);
        if (strings != null) {
            foreach (var str in strings) {
                str_list.add (str);
            }
        } else {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s'", key);
        }

        return str_list;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int val;
        var path = ROOT_GCONF_PATH + section + "/" + key;

        val = this.gconf.get_int (path);

        if (val < min || val > max) {
            throw new ConfigurationError.VALUE_OUT_OF_RANGE (
                                        "Value of '%s' out of range", key);
        }

        return val;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        var int_list = new Gee.ArrayList<int> ();
        var path = ROOT_GCONF_PATH + section + "/" + key;

        unowned SList<int> ints = this.gconf.get_list (path,
                                                       GConf.ValueType.INT);
        if (ints != null) {
            foreach (var num in ints) {
                int_list.add (num);
            }
        } else {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s'", key);
        }

        return int_list;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        bool val;
        var path = ROOT_GCONF_PATH + section + "/" + key;

        unowned GConf.Value value = this.gconf.get (path);
        if (value != null) {
            val = value.get_bool ();
        } else {
            throw new ConfigurationError.NO_VALUE_SET (
                                        "No value available for '%s'", key);
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

    private void enable_upnp (bool enable) {
        var dest_path = Path.build_filename (Environment.get_user_config_dir (),
                                             "autostart",
                                             "rygel.desktop");
        var dest = File.new_for_path (dest_path);

        try {
            if (enable) {
                uint32 res;

                // Start service first
                this.dbus_obj.StartServiceByName (RYGEL_SERVICE,
                        (uint32) 0,
                        out res);

                // Then symlink the desktop file to user's autostart dir
                var source_path = Path.build_filename (
                        BuildConfig.DESKTOP_DIR,
                        "rygel.desktop");
                dest.make_symbolic_link (source_path, null);

                this.set_bool ("general", ENABLED_KEY, true);
            } else {
                // Stop service first
                this.rygel_obj.Shutdown ();

                // Then delete the symlink from user's autostart dir
                dest.delete (null);

                this.set_bool ("general", ENABLED_KEY, false);
            }
        } catch (DBus.Error err) {
            warning ("Failed to %s Rygel service: %s\n",
                     enable? "start": "stop",
                     err.message);
        }
    }
}

