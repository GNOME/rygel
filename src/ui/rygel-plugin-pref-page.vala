/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
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
using Gtk;

public class Rygel.PluginPrefPage : PreferencesPage {
    public PluginPrefPage (Configuration config,
                           string        section) {
        base (config, section, section);

        var enabled = config.get_enabled (section);
        var title = config.get_title (section);
        var udn = config.get_udn (section);

        this.add_boolean_pref (Configuration.ENABLED_KEY,
                               "Enabled",
                               enabled,
                               "Enable/Disable this plugin");

        this.add_string_pref (Configuration.TITLE_KEY,
                              "Title",
                              title,
                              "This is the name that will appear on the " +
                              "client UIs to");

        this.add_string_pref (Configuration.UDN_KEY,
                              "UDN",
                              udn,
                              "The Unique Device Name (UDN) for this plugin." +
                              " Usually, there is no need to change this.");
    }
}
