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

public class Rygel.PluginPrefPage : PreferencesPage {
    const string ENABLED_CHECK = "-enabled-checkbutton";
    const string TITLE_ENTRY = "-title-entry";
    const string UDN_ENTRY = "-udn-entry";

    private CheckButton enabled_check;
    private Entry title_entry;
    private Entry udn_entry;

    public PluginPrefPage (Builder       builder,
                           Configuration config,
                           string        section) {
        base (config, section);

        this.enabled_check = (CheckButton) builder.get_object (section.down () +
                                                               ENABLED_CHECK);
        assert (this.enabled_check != null);
        this.title_entry = (Entry) builder.get_object (section.down () +
                                                       TITLE_ENTRY);
        assert (this.title_entry != null);
        this.udn_entry = (Entry) builder.get_object (section.down () +
                                                     UDN_ENTRY);
        assert (this.udn_entry != null);

        this.enabled_check.active = config.get_enabled (section);
        this.title_entry.set_text (config.get_title (section));
        this.udn_entry.set_text (config.get_udn (section));

        this.enabled_check.toggled += this.on_enabled_check_toggled;
    }

    public override void save () {
        this.config.set_bool (this.section,
                              Configuration.ENABLED_KEY,
                              this.enabled_check.active);
        this.config.set_string (this.section,
                                Configuration.TITLE_KEY,
                                this.title_entry.get_text ());
        this.config.set_string (this.section,
                                Configuration.UDN_KEY,
                                this.udn_entry.get_text ());
    }

    private void on_enabled_check_toggled (CheckButton enabled_check) {
        this.title_entry.sensitive =
        this.udn_entry.sensitive = enabled_check.active;
    }
}
