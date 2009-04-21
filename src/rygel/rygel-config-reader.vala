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
public class Rygel.ConfigReader {
    protected static const string ROOT_GCONF_PATH = "/apps/rygel/";

    protected GConf.Client gconf;

    public bool enable_xbox;
    public string host_ip;
    public int port;

    public ConfigReader () {
        this.gconf = GConf.Client.get_default ();

        this.enable_xbox = this.get_bool ("general", "enable-xbox", false);
        this.host_ip = this.get_string ("general", "host-ip", null);
        this.port = this.get_int ("general", "port", uint16.MIN, uint16.MAX, 0);
    }

    public string get_title (string section) {
        return this.get_string (section, "title", section);
    }

    public string get_udn (string section) {
        var new_udn = Utils.generate_random_udn ();

        return this.get_string (section, "UDN", new_udn);
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

        if (val == null) {
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
            val = this.gconf.get_bool (path);
        } catch (GLib.Error error) {
            val = default_value;
        }

        return val;
    }
}

