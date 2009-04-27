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
    const string IP_ENTRY = "ip-entry";
    const string PORT_SPINBUTTON = "port-spinbutton";

    private Entry ip_entry;
    private SpinButton port_spin;

    public GeneralPrefPage (Builder       builder,
                            Configuration config) throws Error {
        base (config, "general");

        this.ip_entry = (Entry) builder.get_object (IP_ENTRY);
        assert (this.ip_entry != null);
        this.port_spin = (SpinButton) builder.get_object (PORT_SPINBUTTON);
        assert (this.port_spin != null);

        if (config.host_ip != null) {
            this.ip_entry.set_text (config.host_ip);
        }
        this.port_spin.set_value (config.port);
    }

    public override void save () {
        this.config.set_string (this.section,
                                Configuration.IP_KEY,
                                this.ip_entry.get_text ());

        this.config.set_int (this.section,
                             Configuration.PORT_KEY,
                             (int) this.port_spin.get_value ());
    }
}
