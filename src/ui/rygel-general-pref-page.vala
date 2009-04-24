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

public class Rygel.GeneralPrefPage : PreferencesPage {
    public GeneralPrefPage (Configuration config) {
        base (config, "General", "general");

        this.add_string_pref (Configuration.IP_KEY,
                              "IP",
                              this.config.host_ip,
                              "The IP to advertise the UPnP MediaServer on");
        this.add_int_pref (Configuration.PORT_KEY,
                           "Port",
                           this.config.port,
                           uint16.MIN,
                           uint16.MAX,
                           "The port to advertise the UPnP MediaServer on");
    }
}
