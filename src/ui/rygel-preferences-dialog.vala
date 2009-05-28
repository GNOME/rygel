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
using CStuff;

public class Rygel.PreferencesDialog : GLib.Object {
    const string UI_FILE = BuildConfig.DATA_DIR + "/rygel-preferences.ui";
    const string DIALOG = "preferences-dialog";

    Builder builder;
    Dialog dialog;
    ArrayList<PreferencesSection> sections;

    public PreferencesDialog () throws Error {
        var config = Configuration.get_default ();

        this.builder = new Builder ();

        this.builder.add_from_file (UI_FILE);

        this.dialog = (Dialog) this.builder.get_object (DIALOG);
        assert (this.dialog != null);

        this.sections = new ArrayList<PreferencesSection> ();
        this.sections.add (new GeneralPrefSection (this.builder, config));
        this.sections.add (new PluginPrefSection (this.builder,
                                                  config,
                                                  "Tracker"));
        this.sections.add (new PluginPrefSection (this.builder,
                                                  config,
                                                  "DVB"));
        this.sections.add (new FolderPrefSection (this.builder,
                                                  config));

        this.dialog.response += this.on_response;
        this.dialog.delete_event += (dialog, event) => {
                                Gtk.main_quit ();
                                return false;
        };

        this.dialog.show_all ();

    }

    private void on_response (Dialog dialog, int response_id) {
        switch (response_id) {
            case ResponseType.CANCEL:
                Gtk.main_quit ();
                break;
            case ResponseType.OK:
                apply_settings ();
                Gtk.main_quit ();
                break;
            case ResponseType.APPLY:
                apply_settings ();
                break;
        }
    }

    private void apply_settings () {
        foreach (var section in this.sections) {
            section.save ();
        }
    }

    public new void run () {
        Gtk.main ();
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        try {
            var dialog = new PreferencesDialog ();

            dialog.run ();
        } catch (Error err) {
            error ("Failed to create preferences dialog: %s\n", err.message);
        }

        return 0;
    }
}
