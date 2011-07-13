/*
 * Copyright (C) 2008,2010 Nokia Corporation.
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

[DBus (name = "org.gnome.Rygel1")]
public class Rygel.DBusService : Object, DBusInterface {
    private Main main;
    private uint name_id;
    private uint connection_id;

    public DBusService (Main main) {
        this.main = main;
    }

    public void shutdown () throws IOError {
        this.main.exit (0);
    }

    internal void publish () {
        this.name_id = Bus.own_name (BusType.SESSION,
                                     DBusInterface.SERVICE_NAME,
                                     BusNameOwnerFlags.ALLOW_REPLACEMENT |
                                     BusNameOwnerFlags.REPLACE,
                                     this.on_bus_aquired,
                                     this.on_name_available,
                                     this.on_name_lost);
    }

    internal void unpublish () {
        if (connection_id != 0) {
            try {
                var connection = Bus.get_sync (BusType.SESSION);
                connection.unregister_object (this.connection_id);
            } catch (IOError error) {};
        }

        if (name_id != 0) {
            Bus.unown_name (this.name_id);
        }
    }


    private void on_bus_aquired (DBusConnection connection) {
        try {
            this.connection_id = connection.register_object
                                        (DBusInterface.OBJECT_PATH,
                                         this);
        } catch (Error error) { }
    }

    private void on_name_available (DBusConnection connection) {
        this.main.dbus_available ();
    }

    private void on_name_lost (DBusConnection? connection) {
        if (connection == null) {
            // This means there is no DBus available at all
            this.main.dbus_available ();

            return;
        }

        if (this.connection_id != 0) {
            message (_("Another instance of Rygel is taking over. Exiting"));
        } else {
            message (_("Another instance of Rygel is already running."));
        }

        this.main.exit (12);
    }
}

