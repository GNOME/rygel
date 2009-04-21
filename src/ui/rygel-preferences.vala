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

public class Rygel.Preferences : Dialog {
    public Preferences () {
        this.title = "Rygel Preferences";

        var config_editor = new Rygel.ConfigEditor ();

        this.add_string_pref ("IP",
                              config_editor.host_ip,
                              "The IP to advertise the UPnP MediaServer on");
        this.add_int_pref ("Port",
                           config_editor.port,
                           uint16.MIN,
                           uint16.MAX,
                           "The port to advertise the UPnP MediaServer on");
        this.add_boolean_pref ("XBox support",
                               config_editor.enable_xbox,
                               "Enable Xbox support");

        this.add_button (STOCK_OK, ResponseType.ACCEPT);
        this.add_button (STOCK_APPLY, ResponseType.APPLY);
        this.add_button (STOCK_CANCEL, ResponseType.REJECT);

        this.response += this.on_response;

        this.show_all ();
    }

    private void add_string_pref (string  name,
                                  string? current_value,
                                  string  tooltip) {
        var entry = new Entry ();

        if (current_value != null) {
            entry.set_text (current_value);
        }

        this.add_pref_widget (name, entry, tooltip);
    }

    private void add_int_pref (string  name,
                               int     current_value,
                               int     min,
                               int     max,
                               string  tooltip) {
        var adjustment = new Adjustment (current_value,
                                         min,
                                         max,
                                         1.0,
                                         10.0,
                                         10.0);

        var spin = new SpinButton (adjustment, 1.0, 0);

        this.add_pref_widget (name, spin, tooltip);
    }

    private void add_boolean_pref (string  name,
                                   bool    current_value,
                                   string  tooltip) {
        var check = new CheckButton ();

        check.active = current_value;

        this.add_pref_widget (name, check, tooltip);
    }

    private void add_pref_widget (string name,
                                  Widget widget,
                                  string tooltip) {
        var hbox = new HBox (true, 6);

        var label = new Label (name);

        hbox.add (label);
        hbox.add (widget);

        hbox.set_tooltip_text (tooltip);

        this.vbox.add (hbox);
    }

    private void on_response (Preferences pref, int response_id) {
        switch (response_id) {
            case ResponseType.REJECT:
            case ResponseType.ACCEPT:
                Gtk.main_quit ();
                break;
            case ResponseType.APPLY:
                break;
        }
    }

    public new void run () {
        Gtk.main ();
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        var pref = new Preferences ();

        pref.run ();

        return 0;
    }
}
