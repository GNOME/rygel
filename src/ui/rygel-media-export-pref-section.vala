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

public class Rygel.MediaExportPrefSection : PreferencesSection {
    const string ENABLED_CHECK = "-enabled-checkbutton";
    const string TITLE_LABEL = "-title-label";
    const string TITLE_ENTRY = "-title-entry";
    const string NAME = "MediaExport";
    const string URIS_KEY = "uris";
    const string URIS_LABEL = URIS_KEY + "-label";
    const string URIS_TEXTVIEW = URIS_KEY + "-treeview";
    const string URIS_LISTSTORE = URIS_KEY + "-liststore";
    const string URIS_DIALOG = URIS_KEY + "-dialog";
    const string ADD_BUTTON = "add-button";
    const string REMOVE_BUTTON = "remove-button";
    const string CLEAR_BUTTON = "clear-button";

    private CheckButton enabled_check;
    private Entry title_entry;

    private ArrayList<Widget> widgets; // All widgets in this section

    private TreeView treeview;
    private ListStore liststore;
    private FileChooserDialog dialog;

    public MediaExportPrefSection (Builder            builder,
                                   WritableUserConfig config) {
        base (config, NAME);

        this.widgets = new ArrayList<Widget> ();

        this.enabled_check = (CheckButton) builder.get_object (name.down () +
                                                               ENABLED_CHECK);
        assert (this.enabled_check != null);
        this.title_entry = (Entry) builder.get_object (name.down () +
                                                       TITLE_ENTRY);
        assert (this.title_entry != null);
        var title_label = (Label) builder.get_object (name.down () +
                                                      TITLE_LABEL);
        assert (title_label != null);
        this.widgets.add (title_label);

        try {
            this.enabled_check.active = config.get_enabled (name);
        } catch (GLib.Error err) {
            this.enabled_check.active = false;
        }

        string title;
        try {
            title = config.get_title (name);
        } catch (GLib.Error err) {
            title = name;
        }

        title = title.replace ("@REALNAME@", "%n");
        title = title.replace ("@USERNAME@", "%u");
        title = title.replace ("@HOSTNAME@", "%h");
        this.title_entry.set_text (title);

        this.enabled_check.toggled.connect (this.on_enabled_check_toggled);

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
        button.clicked.connect (this.on_add_button_clicked);
        this.widgets.add (button);

        button = (Button) builder.get_object (REMOVE_BUTTON);
        button.clicked.connect (this.on_remove_button_clicked);
        this.widgets.add (button);

        button = (Button) builder.get_object (CLEAR_BUTTON);
        button.clicked.connect (this.on_clear_button_clicked);
        this.widgets.add (button);

        var label = (Label) builder.get_object (URIS_LABEL);
        assert (label != null);
        this.widgets.add (label);

        // Initialize the sensitivity of all widgets
        this.reset_widgets_sensitivity ();
    }

    public override void save () {
        this.config.set_bool (this.name,
                              UserConfig.ENABLED_KEY,
                              this.enabled_check.active);

        var title = this.title_entry.get_text ().replace ("%n", "@REALNAME@");
        title = title.replace ("%u", "@USERNAME@");
        title = title.replace ("%h", "@HOSTNAME@");
        this.config.set_string (this.name, UserConfig.TITLE_KEY, title);

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

    private void reset_widgets_sensitivity () {
        this.title_entry.sensitive = this.enabled_check.active;

        foreach (var widget in this.widgets) {
            widget.sensitive = enabled_check.active;
        }
    }

    private void on_enabled_check_toggled (ToggleButton enabled_check) {
        this.reset_widgets_sensitivity ();
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
