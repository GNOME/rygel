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
    const string IFACE_ENTRY = "iface-entry";
    const string PORT_SPINBUTTON = "port-spinbutton";

    private ComboBoxText iface_entry;
    private SpinButton port_spin;

    private CheckButton upnp_check;

    private ContextManager context_manager;

    public GeneralPrefSection (Builder            builder,
                               WritableUserConfig config) throws Error {
        base (config, "general");

        this.upnp_check = (CheckButton) builder.get_object (UPNP_CHECKBUTTON);
        assert (this.upnp_check != null);
        this.iface_entry = (ComboBoxText) builder.get_object (IFACE_ENTRY);
        assert (this.iface_entry != null);
        this.port_spin = (SpinButton) builder.get_object (PORT_SPINBUTTON);
        assert (this.port_spin != null);

        this.context_manager = new ContextManager (null, 0);

        // Apparently glade/GtkBuilder is unable to do this for us
        this.iface_entry.set_entry_text_column (0);
        try {
            this.iface_entry.append_text (config.get_interface ());
            this.iface_entry.set_active (0);
        } catch (GLib.Error err) {
            // No problem if we fail to read the config, the default values
            // will do just fine. Same goes for rest of the keys.
        }
        try {
            this.port_spin.set_value (config.get_port ());
        } catch (GLib.Error err) {}
        try {
            this.upnp_check.active = this.config.get_upnp_enabled ();
        } catch (GLib.Error err) {}

        this.context_manager.context_available.connect
                                        (this.on_context_available);
        this.context_manager.context_unavailable.connect
                                        (this.on_context_unavailable);
    }

    public override void save () {
        this.config.set_interface (this.iface_entry.get_active_text ());
        this.config.set_port ((int) this.port_spin.get_value ());

        this.config.set_upnp_enabled (this.upnp_check.active);
    }

    private void on_context_available (GUPnP.ContextManager manager,
                                       GUPnP.Context        context) {
        TreeIter iter;

        if (!this.find_interface (context.interface, out iter)) {
            this.iface_entry.append_text (context.interface);
        }
    }

    private void on_context_unavailable (GUPnP.ContextManager manager,
                                         GUPnP.Context        context) {
        TreeIter iter;

        if (this.find_interface (context.interface, out iter)) {
            var list_store = this.iface_entry.model as ListStore;
            list_store.remove (iter);
        }
    }

    private bool find_interface (string iface, out TreeIter iter) {
        var model = this.iface_entry.model;
        var more = model.get_iter_first (out iter);
        while (more) {
            model.get (iter, 0, &name, -1);

            if (name == iface) {
                break;
            }

            more = model.iter_next (ref iter);
        }

        return more;
    }
}
