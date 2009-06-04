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
using Gee;

public class Rygel.FolderPrefSection : Rygel.PluginPrefSection {
    const string NAME = "Folder";
    const string FOLDERS_KEY = "folders";
    const string FOLDERS_TEXTVIEW = FOLDERS_KEY + "-treeview";
    const string FOLDERS_LISTSTORE = FOLDERS_KEY + "-liststore";
    const string FOLDERS_DIALOG = FOLDERS_KEY + "-dialog";
    const string ADD_BUTTON = "add-button";
    const string REMOVE_BUTTON = "remove-button";
    const string CLEAR_BUTTON = "clear-button";

    private TreeView treeview;
    private ListStore liststore;
    private FileChooserDialog dialog;

    public FolderPrefSection (Builder       builder,
                              Configuration config) {
        base (builder, config, NAME);

        this.treeview = (TreeView) builder.get_object (FOLDERS_TEXTVIEW);
        assert (this.treeview != null);
        this.liststore = (ListStore) builder.get_object (FOLDERS_LISTSTORE);
        assert (this.liststore != null);
        this.dialog = (FileChooserDialog) builder.get_object (FOLDERS_DIALOG);
        assert (this.dialog != null);

        treeview.insert_column_with_attributes (-1,
                                                "paths",
                                                new CellRendererText (),
                                                "text",
                                                0,
                                                null);

        var folders = config.get_string_list (this.name, FOLDERS_KEY);
        foreach (var folder in folders) {
            TreeIter iter;

            this.liststore.append (out iter);
            this.liststore.set (iter, 0, folder, -1);
        }

        var button = (Button) builder.get_object (ADD_BUTTON);
        button.clicked += this.on_add_button_clicked;

        button = (Button) builder.get_object (REMOVE_BUTTON);
        button.clicked += this.on_remove_button_clicked;

        button = (Button) builder.get_object (CLEAR_BUTTON);
        button.clicked += this.on_clear_button_clicked;
    }

    public override void save () {
        base.save ();

        TreeIter iter;
        var folder_list = new ArrayList<string> ();

        if (this.liststore.get_iter_first (out iter)) {
            do {
                string folder;

                this.liststore.get (iter, 0, out folder, -1);
                folder_list.add (folder);
            } while (this.liststore.iter_next (ref iter));
        }

        this.config.set_string_list (this.name, FOLDERS_KEY, folder_list);
    }

    protected override void on_enabled_check_toggled (
                                        CheckButton enabled_check) {
        base.on_enabled_check_toggled (enabled_check);

        this.treeview.sensitive = enabled_check.active;
    }

    private void on_add_button_clicked (Button button) {
        if (this.dialog.run () == ResponseType.OK) {
            TreeIter iter;

            var uris = this.dialog.get_uris ();

            foreach (var uri in uris) {
                this.liststore.append (out iter);
                this.liststore.set (iter, 0, uri, -1);
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
