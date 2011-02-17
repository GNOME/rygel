/*
 * Copyright (C) 2009 Nokia Corporation.
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
using GUPnP;

public class Rygel.GeneralPrefSection : PreferencesSection {
    const string UPNP_CHECKBUTTON = "upnp-checkbutton";

    private CheckButton upnp_check;

    public GeneralPrefSection (Builder            builder,
                               WritableUserConfig config) throws Error {
        base (config, "general");

        this.upnp_check = (CheckButton) builder.get_object (UPNP_CHECKBUTTON);
        assert (this.upnp_check != null);

        try {
            this.upnp_check.active = this.config.get_upnp_enabled ();
        } catch (GLib.Error err) {}
    }

    public override void save () {
        this.config.set_upnp_enabled (this.upnp_check.active);
    }
}
