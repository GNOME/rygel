/*
 * Copyright (C) 2009,2011 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */
using Gtk;
using GUPnP;
using Gee;

public class Rygel.NetworkPrefSection : PreferencesSection {
    const string IFACE_STORE = "iface-liststore";
    const string NETWORKS_STORE = "networks-liststore";
    const string TREEVIEW = "networks-treeview";
    const string TREE_SELECTION = "networks-tree-selection";

    private Gtk.ListStore iface_store;
    private Gtk.ListStore networks_store;
    private TreeView treeview;
    private TreeSelection tree_selection;
    private Grid grid;
    private Button remove_button;

    private ContextManager context_manager;

    public NetworkPrefSection (Builder            builder,
                               WritableUserConfig config) throws Error {
        base (config, "general");

        this.iface_store = builder.get_object (IFACE_STORE) as Gtk.ListStore;
        assert (this.iface_store != null);

        this.networks_store = builder.get_object (NETWORKS_STORE) as Gtk.ListStore;
        assert (this.networks_store != null);

        this.tree_selection = builder.get_object (TREE_SELECTION) as
            TreeSelection;

        var renderer = builder.get_object ("cellrenderertext2")
                                        as CellRendererCombo;
        renderer.edited.connect ( (path, new_) => {
            TreeIter iter;
            networks_store.get_iter_from_string (out iter, path);
            networks_store.set (iter, 0, new_);
        });

        this.treeview = builder.get_object (TREEVIEW) as TreeView;

        this.remove_button = builder.get_object ("network-remove-button")
                                        as Button;
        remove_button.clicked.connect (this.on_remove_button_clicked);

        var add_button = builder.get_object ("network-add-button")
                                       as Button;
        add_button.clicked.connect ( () => {
            TreeIter iter;
            networks_store.append (out iter);
            var path = networks_store.get_path (iter);
            this.treeview.set_cursor (path,
                                      this.treeview.get_column (0),
                                      true);
            this.treeview.grab_focus ();
        });

        this.grid = builder.get_object ("grid4") as Grid;
        this.context_manager = ContextManager.create (0);

        try {
            var interfaces = config.get_interfaces ();
            foreach (var iface in interfaces) {
                TreeIter iter;
                networks_store.append (out iter);
                networks_store.set (iter, 0, iface);
            }
        } catch (GLib.Error err) {
            // No problem if we fail to read the config, the default values
            // will do just fine. Same goes for rest of the keys.
        }

        this.context_manager.context_available.connect
                                        (this.on_context_available);
        this.context_manager.context_unavailable.connect
                                        (this.on_context_unavailable);

        this.on_tree_selection_changed ();
        this.tree_selection.changed.connect (this.on_tree_selection_changed);
    }

    public override void save () {
        TreeIter iter;
        var uri_list = new Gee.ArrayList<string> ();

        if (this.networks_store.get_iter_first (out iter)) {
            do {
                string uri;

                this.networks_store.get (iter, 0, out uri, -1);
                uri_list.add (uri);
            } while (this.networks_store.iter_next (ref iter));
        }

        this.config.set_string_list ("general", "interface", uri_list);
    }

    public override void set_sensitivity (bool sensitivity) {
        this.grid.sensitive = sensitivity;
    }

    private void on_context_available (GUPnP.ContextManager manager,
                                       GUPnP.Context        context) {
        TreeIter iter;

        if (!this.find_interface (context.interface, out iter)) {
            this.iface_store.append (out iter);
            this.iface_store.set (iter, 0, context.interface);
        }
    }

    private void on_context_unavailable (GUPnP.ContextManager manager,
                                         GUPnP.Context        context) {
        TreeIter iter;

        if (this.find_interface (context.interface, out iter)) {
            this.iface_store.remove (ref iter);
        }
    }

    private void on_remove_button_clicked (Button button) {
        var selection = this.treeview.get_selection ();
        var rows = selection.get_selected_rows (null);

        // First get permanent references to rows
        var row_refs = new Gee.ArrayList<TreeRowReference> ();
        foreach (var row in rows) {
            row_refs.add (new TreeRowReference (this.networks_store, row));
        }

        // Now we can safely remove rows
        foreach (var row_ref in row_refs) {
           TreeIter iter;

           var path = row_ref.get_path ();
           this.networks_store.get_iter (out iter, path);

           this.networks_store.remove (ref iter);
        }
    }


    private bool find_interface (string iface, out TreeIter iter) {
        var model = this.iface_store;
        var more = model.get_iter_first (out iter);
        string name = null;

        while (more) {
            model.get (iter, 0, &name, -1);

            if (name == iface) {
                break;
            }

            more = model.iter_next (ref iter);
        }

        return more;
    }

    private void on_tree_selection_changed () {
        // Remove button cannot be sensitive if no row is selected
        if (tree_selection.get_selected (null, null)) {
            remove_button.set_sensitive (true);
        } else {
            remove_button.set_sensitive (false);
        }
    }
}
