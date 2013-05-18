/*
 * Copyright (C) 2009,2011 Nokia Corporation.
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

public class Rygel.NetworkPrefSection : PreferencesSection {
    const string IFACE_ENTRY = "iface-entry";

    private ComboBoxText iface_entry;

    private ContextManager context_manager;

    public NetworkPrefSection (Builder            builder,
                               WritableUserConfig config) throws Error {
        base (config, "general");

        this.iface_entry = (ComboBoxText) builder.get_object (IFACE_ENTRY);
        assert (this.iface_entry != null);

        this.context_manager = ContextManager.create (0);

        try {
            var interfaces = config.get_interfaces ();
            if (interfaces != null) {
                int num_items;

                this.iface_entry.append_text (interfaces[0]);
                num_items = this.count_items (this.iface_entry.model);
                this.iface_entry.set_active (num_items - 1);
            }
        } catch (GLib.Error err) {
            // No problem if we fail to read the config, the default values
            // will do just fine. Same goes for rest of the keys.
        }

        this.context_manager.context_available.connect
                                        (this.on_context_available);
        this.context_manager.context_unavailable.connect
                                        (this.on_context_unavailable);
    }

    public override void save () {
        var iface = this.iface_entry.get_active_text ();

        // The zeroth item is "Any" network. -1 represents no active item.
        if (this.iface_entry.active <= 0 ) {
            iface = "";
        }

        this.config.set_interface (iface);
    }

    public override void set_sensitivity (bool sensitivity) {
        iface_entry.sensitive = sensitivity;
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

    private int count_items (TreeModel model) {
        TreeIter iter;
        int count = 0;
        var more = model.get_iter_first (out iter);

        while (more) {
            count++;
            more = model.iter_next (ref iter);
        }

        return count;
    }
}
