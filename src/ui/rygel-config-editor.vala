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
 * User configuration editor for Rygel.
 */
public class Rygel.ConfigEditor : ConfigReader {
    public ConfigEditor () {
        base ();
    }

    public void set_title (string section, string title) {
        this.set_string (section, "title", title);
    }

    public void set_udn (string section, string? udn) {
        var value = udn;

        if (value == null) {
            value = Utils.generate_random_udn ();
        }

        this.set_string (section, "UDN", value);
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

