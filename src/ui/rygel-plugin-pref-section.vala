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

public class Rygel.PluginPrefSection : PreferencesSection {
    const string ENABLED_CHECK = "-enabled-checkbutton";
    const string TITLE_ENTRY = "-title-entry";

    private CheckButton enabled_check;
    private Entry title_entry;

    public PluginPrefSection (Builder       builder,
                              Configuration config,
                              string        name) {
        base (config, name);

        this.enabled_check = (CheckButton) builder.get_object (name.down () +
                                                               ENABLED_CHECK);
        assert (this.enabled_check != null);
        this.title_entry = (Entry) builder.get_object (name.down () +
                                                       TITLE_ENTRY);
        assert (this.title_entry != null);

        this.enabled_check.active = config.get_enabled (name);

        var title = config.get_title (name, name).replace ("@REALNAME@", "%n");
        title = title.replace ("@USERNAME@", "%u");
        title = title.replace ("@HOSTNAME@", "%h");
        this.title_entry.set_text (title);

        this.enabled_check.toggled += this.on_enabled_check_toggled;
    }

    public override void save () {
        this.config.set_bool (this.name,
                              Configuration.ENABLED_KEY,
                              this.enabled_check.active);

        var title = this.title_entry.get_text ().replace ("%n", "@REALNAME@");
        title = title.replace ("%u", "@USERNAME@");
        title = title.replace ("%h", "@HOSTNAME@");
        this.config.set_string (this.name, Configuration.TITLE_KEY, title);
    }

    protected virtual void on_enabled_check_toggled (
                                CheckButton enabled_check) {
        this.title_entry.sensitive = enabled_check.active;
    }
}
