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
    ConfigEditor config_editor;

    public Preferences () {
        this.title = "Rygel Preferences";

        this.config_editor = new ConfigEditor ();

        this.add_string_pref (ConfigReader.IP_KEY,
                              "IP",
                              this.config_editor.host_ip,
                              "The IP to advertise the UPnP MediaServer on");
        this.add_int_pref (ConfigReader.PORT_KEY,
                           "Port",
                           this.config_editor.port,
                           uint16.MIN,
                           uint16.MAX,
                           "The port to advertise the UPnP MediaServer on");
        this.add_boolean_pref (ConfigReader.XBOX_KEY,
                               "XBox support",
                               this.config_editor.enable_xbox,
                               "Enable Xbox support");

        this.add_button (STOCK_OK, ResponseType.ACCEPT);
        this.add_button (STOCK_APPLY, ResponseType.APPLY);
        this.add_button (STOCK_CANCEL, ResponseType.REJECT);

        this.response += this.on_response;

        this.show_all ();
    }

    private void add_string_pref (string  name,
                                  string  title,
                                  string? current_value,
                                  string  tooltip) {
        var entry = new Entry ();

        if (current_value != null) {
            entry.set_text (current_value);
        }

        this.add_pref_widget (name, title, entry, tooltip);
    }

    private void add_int_pref (string  name,
                               string  title,
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

        this.add_pref_widget (name, title, spin, tooltip);
    }

    private void add_boolean_pref (string  name,
                                   string  title,
                                   bool    current_value,
                                   string  tooltip) {
        var check = new CheckButton ();

        check.active = current_value;

        this.add_pref_widget (name, title, check, tooltip);
    }

    private void add_pref_widget (string name,
                                  string title,
                                  Widget widget,
                                  string tooltip) {
        var hbox = new HBox (true, 6);

        var label = new Label (title);

        hbox.add (label);
        hbox.add (widget);

        hbox.set_tooltip_text (tooltip);
        widget.set_name (name);

        this.vbox.add (hbox);
    }

    private void on_response (Preferences pref, int response_id) {
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
        foreach (var child in this.vbox.get_children ()) {
            if (!(child is HBox)) {
                break;
            }

            var hbox = (HBox) child;

            foreach (var widget in hbox.get_children ()) {
                if (widget is Entry) {
                        var name = widget.get_name ();
                        var text = ((Entry) widget).get_text ();

                        this.config_editor.set_string ("general", name, text);
                }
            }
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
