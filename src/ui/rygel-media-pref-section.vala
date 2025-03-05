/*
 * Copyright (C) 2009 Nokia Corporation.
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
using Gee;

public class Rygel.MediaPrefSection : PreferencesSection {
    const string NAME = "MediaExport";
    const string URIS_KEY = "uris";
    const string URIS_TEXTVIEW = URIS_KEY + "-treeview";
    const string URIS_LISTSTORE = URIS_KEY + "-liststore";
    const string URIS_DIALOG = URIS_KEY + "-dialog";
    const string ADD_BUTTON = "add-button";
    const string REMOVE_BUTTON = "remove-button";
    const string TREE_SELECTION = "treeview-selection";

    private ArrayList<Widget> widgets; // All widgets in this section

    private TreeView treeview;
    private Gtk.ListStore liststore;
    private TreeSelection tree_selection;
    private FileDialog dialog;
    private Button remove_button;

    public MediaPrefSection (Builder            builder,
                             WritableUserConfig config) {
        base (config, NAME);

        this.widgets = new ArrayList<Widget> ();

        this.treeview = (TreeView) builder.get_object (URIS_TEXTVIEW);
        assert (this.treeview != null);
        this.liststore = (Gtk.ListStore) builder.get_object (URIS_LISTSTORE);
        assert (this.liststore != null);
        this.tree_selection = builder.get_object (TREE_SELECTION)
                                                  as TreeSelection;
        assert (this.tree_selection != null);
        this.dialog = (FileDialog) builder.get_object (URIS_DIALOG);
        assert (this.dialog != null);

        this.widgets.add (this.treeview);

        try {
            var uris = config.get_string_list (this.name, URIS_KEY);
            foreach (var uri in uris) {
                var real_uri = this.get_real_uri (uri);
                TreeIter iter;

                this.liststore.append (out iter);
                this.liststore.set (iter, 0, real_uri, -1);
            }
        } catch (GLib.Error err) {} // Nevermind

        this.dialog.set_initial_folder (File.new_for_commandline_arg (Environment.get_home_dir ()));
        this.dialog.modal = true;

        var add_button = builder.get_object (ADD_BUTTON) as Button;
        add_button.clicked.connect (this.on_add_button_clicked);
        this.widgets.add (add_button);

        remove_button = builder.get_object (REMOVE_BUTTON) as Button;
        remove_button.clicked.connect (this.on_remove_button_clicked);
        this.widgets.add (remove_button);

        // Update the sensitivity of the remove button
        this.on_tree_selection_changed ();
        this.tree_selection.changed.connect (this.on_tree_selection_changed);
    }

    public override void save () {
        TreeIter iter;
        var uri_list = new ArrayList<string> ();

        if (this.liststore.get_iter_first (out iter)) {
            do {
                string uri;

                this.liststore.get (iter, 0, out uri, -1);
                uri = this.uri_to_magic_variable (uri);
                uri_list.add (uri);
            } while (this.liststore.iter_next (ref iter));
        }

        this.config.set_string_list (this.name, URIS_KEY, uri_list);
    }

    public override void set_sensitivity (bool sensitivity) {
        foreach (var widget in this.widgets) {
            widget.sensitive = sensitivity;
        }

        // Force an update of the remove button.
        if (sensitivity) {
            this.on_tree_selection_changed ();
        }
    }

    private void on_add_button_clicked (Button button) {
        add_folders.begin();
    }

    private async void add_folders() {
        try {
            var folders = yield this.dialog.select_multiple_folders ((Gtk.Window)(this.treeview.get_root()), null);
            TreeIter iter;
            for (int i = 0; i< folders.get_n_items(); i++) {
                var dir = ((File)folders.get_item(i));
                string path = dir.get_path ();

                if (path == null) {
                    path = dir.get_uri ();
                }

                this.liststore.append (out iter);
                this.liststore.set (iter, 0, path, -1);
            }
        } catch (Error err) {
            warning ("Failed to chose folders: %s", err.message);
        }
    }

    private void on_remove_button_clicked (Button button) {
        var selection = this.treeview.get_selection ();
        var rows = selection.get_selected_rows (null);

        // First get permanent references to rows
        var row_refs = new ArrayList<TreeRowReference> ();
        foreach (var row in rows) {
            row_refs.add (new TreeRowReference (this.liststore, row));
        }

        // Now we can safely remove rows
        foreach (var row_ref in row_refs) {
           TreeIter iter;

           var path = row_ref.get_path ();
           this.liststore.get_iter (out iter, path);

           this.liststore.remove (ref iter);
        }
    }

    private string get_real_uri (string uri) {
        switch (uri) {
        case "@MUSIC@":
            return Environment.get_user_special_dir (UserDirectory.MUSIC);
        case "@VIDEOS@":
            return Environment.get_user_special_dir (UserDirectory.VIDEOS);
        case "@PICTURES@":
            return Environment.get_user_special_dir (UserDirectory.PICTURES);
        default:
            return uri;
        }
    }

    private string uri_to_magic_variable (string uri) {
        if (uri == Environment.get_user_special_dir (UserDirectory.MUSIC)) {
            return "@MUSIC@";
        } else if (uri ==
                   Environment.get_user_special_dir (UserDirectory.VIDEOS)) {
            return "@VIDEOS@";
        } else if (uri ==
                   Environment.get_user_special_dir (UserDirectory.PICTURES)) {
            return "@PICTURES@";
        } else {
            return uri;
        }
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
