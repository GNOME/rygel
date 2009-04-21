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
    private static const string ROOT_GCONF_PATH = "/apps/rygel/";

    private GConf.Client gconf;

    public bool enable_xbox;
    public string host_ip;
    public int port;

    public ConfigReader () {
        this.gconf = GConf.Client.get_default ();

        try {
            this.enable_xbox = this.gconf.get_bool (ROOT_GCONF_PATH +
                                                    "enable-xbox");
            this.host_ip = this.gconf.get_string (ROOT_GCONF_PATH + "host-ip");
            this.port = this.gconf.get_int (ROOT_GCONF_PATH + "port");
        } catch (GLib.Error error) {
            this.enable_xbox = false;
            this.host_ip = null;
            this.port = 0;
        }
    }

    public string get_title (string section) {
        return this.get_string (section, "Title", section);
    }

    public string get_udn (string section) {
        var new_udn = Utils.generate_random_udn ();

        return this.get_string (section, "UDN", new_udn);
    }

    private string get_string (string section,
                               string key,
                               string default_value) {
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
}

