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

public class Rygel.PluginPrefSection : PreferencesSection {
    const string ENABLED_CHECK = "-enabled-checkbutton";
    const string TITLE_LABEL = "-title-label";
    const string TITLE_ENTRY = "-title-entry";

    private CheckButton enabled_check;
    private Entry title_entry;

    protected ArrayList<Widget> widgets; // All widgets in this section

    public PluginPrefSection (Builder    builder,
                              UserConfig config,
                              string     name) {
        base (config, name);

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

        this.enabled_check.toggled += this.on_enabled_check_toggled;
    }

    public override void save () {
        this.config.set_bool (this.name,
                              UserConfig.ENABLED_KEY,
                              this.enabled_check.active);

        var title = this.title_entry.get_text ().replace ("%n", "@REALNAME@");
        title = title.replace ("%u", "@USERNAME@");
        title = title.replace ("%h", "@HOSTNAME@");
        this.config.set_string (this.name, UserConfig.TITLE_KEY, title);
    }

    protected void reset_widgets_sensitivity () {
        this.title_entry.sensitive = this.enabled_check.active;

        foreach (var widget in this.widgets) {
            widget.sensitive = enabled_check.active;
        }
    }

    private void on_enabled_check_toggled (CheckButton enabled_check) {
        this.reset_widgets_sensitivity ();
    }
}
