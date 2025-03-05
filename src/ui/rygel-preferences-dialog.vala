/*
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2012 Openismus GmbH.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

public class Rygel.PreferencesDialog : Gtk.Application {
    const string UI_FILE = "/org/gnome/Rygel/Preferences/rygel-preferences.ui";
    const string DIALOG = "preferences-dialog";
    const string UPNP_CHECKBUTTON = "upnp-checkbutton";
    const string CLOSE_BUTTON = "close-button";

    private WritableUserConfig config;
    private Builder builder;
    private ApplicationWindow dialog;
    private Switch upnp_check;
    private ArrayList<PreferencesSection> sections;

    public PreferencesDialog () throws Error {
        Object(application_id : "org.gnome.Rygel.Preferences",
               flags: GLib.ApplicationFlags.FLAGS_NONE);

        Environment.set_application_name ("RygelPreferences");

        this.config = new WritableUserConfig ();
        this.builder = new Builder ();

        this.builder.add_from_resource (UI_FILE);

        this.dialog = (Gtk.ApplicationWindow) this.builder.get_object (DIALOG);
        assert (this.dialog != null);
        this.upnp_check = (Switch) builder.get_object (UPNP_CHECKBUTTON);
        assert (this.upnp_check != null);

        this.upnp_check.active = this.config.is_upnp_enabled ();

        this.sections = new ArrayList<PreferencesSection> ();
        this.sections.add (new NetworkPrefSection (this.builder, this.config));
        this.sections.add (new MediaPrefSection (this.builder, this.config));

        // All sections must be disabled if sharing is disabled
        this.on_upnp_switch_toggled ();
        this.upnp_check.notify["active"].connect ( () => {
            this.on_upnp_switch_toggled ();
        });
    }

    public override void activate() {
        this.dialog.set_application (this);
        this.dialog.present ();
    }

    public override void shutdown () {
        this.config.set_upnp_enabled (this.upnp_check.active);
        foreach (var section in this.sections) {
            section.save ();
        }

        this.config.save ();

        base.shutdown ();
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (BuildConfig.GETTEXT_PACKAGE,
                             BuildConfig.LOCALEDIR);
        Intl.bind_textdomain_codeset (BuildConfig.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (BuildConfig.GETTEXT_PACKAGE);

        Gtk.init();

        try {
            MetaConfig.register_configuration (UserConfig.get_default ());
            var app = new PreferencesDialog ();

            app.run ();
        } catch (Error err) {
            error (_("Failed to create preferences dialog: %s"), err.message);
        }

        return 0;
    }

    private void on_upnp_switch_toggled () {
        foreach (var section in this.sections) {
            section.set_sensitivity (this.upnp_check.active);
        }
    }
}
