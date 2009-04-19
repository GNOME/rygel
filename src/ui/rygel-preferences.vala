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

        this.add_button (STOCK_OK, ResponseType.ACCEPT);
        this.add_button (STOCK_APPLY, ResponseType.APPLY);
        this.add_button (STOCK_CANCEL, ResponseType.REJECT);

        this.response += this.on_response;

        this.show_all ();
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
