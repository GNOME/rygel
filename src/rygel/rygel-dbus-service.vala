/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

[DBus (name = "org.gnome.Rygel")]
public class Rygel.DBusService : Object {
    private static string RYGEL_SERVICE = "org.gnome.Rygel";
    private static string RYGEL_PATH = "/org/gnome/Rygel";

    private Main main;

    public DBusService (Main main) throws GLib.Error {
        this.main = main;

        var conn = DBus.Bus.get (DBus.BusType. SESSION);

        dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                                   "/org/freedesktop/DBus",
                                                   "org.freedesktop.DBus");

        // try to register service in session bus
        uint request_name_result = bus.request_name (RYGEL_SERVICE,
                                                     (uint) 0);

        if (request_name_result != DBus.RequestNameReply.PRIMARY_OWNER) {
            warning ("Failed to start D-Bus service, name '%s' already taken",
                     RYGEL_SERVICE);
        }

        conn.register_object (RYGEL_PATH, this);
    }

    public void Shutdown () {
        this.main.exit (0);
    }
}

