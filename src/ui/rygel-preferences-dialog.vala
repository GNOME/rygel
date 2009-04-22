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

public class Rygel.PreferencesDialog : Dialog {
    Notebook notebook;

    public PreferencesDialog () {
        this.title = "Rygel Preferences";

        var config_editor = new ConfigEditor ();

        this.notebook = new Notebook ();

        var pref_vbox = new GeneralPrefVBox (config_editor);
        var label = new Label (pref_vbox.title);
        this.notebook.append_page (pref_vbox, label);

        this.vbox.add (this.notebook);

        this.add_button (STOCK_OK, ResponseType.ACCEPT);
        this.add_button (STOCK_APPLY, ResponseType.APPLY);
        this.add_button (STOCK_CANCEL, ResponseType.REJECT);

        this.response += this.on_response;

        this.show_all ();
    }

    private void on_response (PreferencesDialog dialog, int response_id) {
        switch (response_id) {
            case ResponseType.REJECT:
                Gtk.main_quit ();
                break;
            case ResponseType.ACCEPT:
                apply_settings ();
                Gtk.main_quit ();
                break;
            case ResponseType.APPLY:
                apply_settings ();
                break;
        }
    }

    private void apply_settings () {
        foreach (var child in this.notebook.get_children ()) {
            if (!(child is PreferencesVBox)) {
                break;
            }

            ((PreferencesVBox) child).save ();
        }
    }

    public new void run () {
        Gtk.main ();
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var dialog = new PreferencesDialog ();

        dialog.run ();

        return 0;
    }
}
