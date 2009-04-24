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
public class Rygel.Configuration {
    protected static const string ROOT_GCONF_PATH = "/apps/rygel/";
    protected static const string IP_KEY = "host-ip";
    protected static const string PORT_KEY = "port";
    protected static const string XBOX_KEY = "enable-xbox";
    protected static const string ENABLED_KEY = "enabled";
    protected static const string TITLE_KEY = "title";
    protected static const string UDN_KEY = "UDN";

    protected GConf.Client gconf;

    public bool enable_xbox;
    public string host_ip;
    public int port;

    public Configuration () {
        this.gconf = GConf.Client.get_default ();

        this.enable_xbox = this.get_bool ("general", XBOX_KEY, false);
        this.host_ip = this.get_string ("general", IP_KEY, null);
        this.port = this.get_int ("general",
                                  PORT_KEY,
                                  uint16.MIN,
                                  uint16.MAX,
                                  0);
    }

    public bool get_enabled (string section) {
        return this.get_bool (section, ENABLED_KEY, true);
    }

    public string get_title (string section) {
        return this.get_string (section, TITLE_KEY, section);
    }

    public string get_udn (string section) {
        var udn = this.get_string (section, UDN_KEY, null);
        if (udn == null) {
            udn = Utils.generate_random_udn ();

            this.set_string (section, UDN_KEY, udn);
        }

        return udn;
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

