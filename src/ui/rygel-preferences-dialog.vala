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

public class Rygel.PreferencesDialog : GLib.Object {
    const string UI_FILE = BuildConfig.DATA_DIR + "/rygel-preferences.ui";
    const string DIALOG = "preferences-dialog";
    const string ICON = BuildConfig.SMALL_ICON_DIR + "/rygel.png";

    WritableUserConfig config;
    Builder builder;
    Dialog dialog;
    ArrayList<PreferencesSection> sections;

    public PreferencesDialog () throws Error {
        this.config = new WritableUserConfig ();
        this.builder = new Builder ();

        this.builder.add_from_file (UI_FILE);

        this.dialog = (Dialog) this.builder.get_object (DIALOG);
        assert (this.dialog != null);

        this.dialog.set_icon_from_file (ICON);

        this.sections = new ArrayList<PreferencesSection> ();
        this.sections.add (new GeneralPrefSection (this.builder, this.config));
        this.sections.add (new MediaExportPrefSection (this.builder,
                                                       this.config));
    }

    public void run () {
        this.dialog.run ();

        foreach (var section in this.sections) {
            section.save ();
        }

        this.config.save ();
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (BuildConfig.GETTEXT_PACKAGE,
                             BuildConfig.LOCALEDIR);
        Intl.bind_textdomain_codeset (BuildConfig.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (BuildConfig.GETTEXT_PACKAGE);

        Gtk.init (ref args);

        try {
            var dialog = new PreferencesDialog ();

            dialog.run ();
        } catch (Error err) {
            error (_("Failed to create preferences dialog: %s"), err.message);
        }

        return 0;
    }
}
