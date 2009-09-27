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
using Gee;

public class Rygel.MediaExportPrefSection : Rygel.PluginPrefSection {
    const string NAME = "MediaExport";
    const string URIS_KEY = "uris";
    const string URIS_TEXTVIEW = URIS_KEY + "-treeview";
    const string URIS_LISTSTORE = URIS_KEY + "-liststore";
    const string URIS_DIALOG = URIS_KEY + "-dialog";
    const string ADD_BUTTON = "add-button";
    const string REMOVE_BUTTON = "remove-button";
    const string CLEAR_BUTTON = "clear-button";

    private TreeView treeview;
    private ListStore liststore;
    private FileChooserDialog dialog;

    public MediaExportPrefSection (Builder    builder,
                                   UserConfig config) {
        base (builder, config, NAME);

        this.treeview = (TreeView) builder.get_object (URIS_TEXTVIEW);
        assert (this.treeview != null);
        this.liststore = (ListStore) builder.get_object (URIS_LISTSTORE);
        assert (this.liststore != null);
        this.dialog = (FileChooserDialog) builder.get_object (URIS_DIALOG);
        assert (this.dialog != null);

        treeview.insert_column_with_attributes (-1,
                                                "paths",
                                                new CellRendererText (),
                                                "text",
                                                0,
                                                null);
        this.widgets.add (this.treeview);

        try {
            var uris = config.get_string_list (this.name, URIS_KEY);
            foreach (var uri in uris) {
                TreeIter iter;

                this.liststore.append (out iter);
                this.liststore.set (iter, 0, uri, -1);
            }
        } catch (GLib.Error err) {} // Nevermind

        this.dialog.set_current_folder (Environment.get_home_dir ());
        this.dialog.show_hidden = false;

        var button = (Button) builder.get_object (ADD_BUTTON);
        button.clicked += this.on_add_button_clicked;
        this.widgets.add (button);

        button = (Button) builder.get_object (REMOVE_BUTTON);
        button.clicked += this.on_remove_button_clicked;
        this.widgets.add (button);

        button = (Button) builder.get_object (CLEAR_BUTTON);
        button.clicked += this.on_clear_button_clicked;
        this.widgets.add (button);
    }

    public override void save () {
        base.save ();

        TreeIter iter;
        var uri_list = new ArrayList<string> ();

        if (this.liststore.get_iter_first (out iter)) {
            do {
                string uri;

                this.liststore.get (iter, 0, out uri, -1);
                uri_list.add (uri);
            } while (this.liststore.iter_next (ref iter));
        }

        this.config.set_string_list (this.name, URIS_KEY, uri_list);
    }

    private void on_add_button_clicked (Button button) {
        if (this.dialog.run () == ResponseType.OK) {
            TreeIter iter;

            var dirs = this.dialog.get_files ();

            foreach (var dir in dirs) {
                string path = dir.get_path ();

                if (path == null) {
                    path = dir.get_uri ();
                }

                this.liststore.append (out iter);
                this.liststore.set (iter, 0, path, -1);
            }
        }

        this.dialog.hide ();
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

           this.liststore.remove (iter);
        }
    }

    private void on_clear_button_clicked (Button button) {
        this.liststore.clear ();
    }
}
