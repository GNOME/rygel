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

public class Rygel.PreferencesVBox : VBox {
    protected Configuration config;

    public string title;
    public string section;

    public PreferencesVBox (Configuration config,
                            string        title,
                            string        section) {
        this.section = section;
        this.title = title;

        this.config = config;
    }

    protected void add_string_pref (string  name,
                                    string  title,
                                    string? current_value,
                                    string  tooltip) {
        var entry = new Entry ();

        if (current_value != null) {
            entry.set_text (current_value);
        }

        this.add_pref_widget (name, title, entry, tooltip);
    }

    protected void add_int_pref (string  name,
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

    protected void add_boolean_pref (string  name,
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

        this.add (hbox);
    }

    public void save () {
        foreach (var child in this.get_children ()) {
            if (!(child is HBox)) {
                break;
            }

            var hbox = (HBox) child;

            foreach (var widget in hbox.get_children ()) {
                if (widget is SpinButton) {
                        var name = widget.get_name ();
                        var number = ((SpinButton) widget).get_value ();

                        this.config.set_int (this.section, name, (int) number);
                } else if (widget is Entry) {
                        var name = widget.get_name ();
                        var text = ((Entry) widget).get_text ();

                        this.config.set_string (this.section, name, text);
                } else if (widget is CheckButton) {
                        var name = widget.get_name ();
                        var active = ((CheckButton) widget).get_active ();

                        this.config.set_bool (this.section, name, active);
                }
            }
        }
    }
}
