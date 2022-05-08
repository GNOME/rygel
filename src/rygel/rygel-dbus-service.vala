/*
 * Copyright (C) 2008,2010 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

[DBus (name = "org.gnome.Rygel1")]
internal class Rygel.DBusService : Object, DBusInterface {
    private Application main;
    private uint name_id;
    private uint connection_id;

    public DBusService (Application main) {
        this.main = main;
    }

    public void shutdown () throws IOError, DBusError {
        main.release ();
    }

    internal void publish (DBusConnection connection) {
        this.name_id = Bus.own_name_on_connection (connection,
                                     DBusInterface.SERVICE_NAME,
                                     BusNameOwnerFlags.NONE,
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


    private void on_name_available (DBusConnection connection) {
        try {
            connection.register_object (DBusInterface.OBJECT_PATH, this);
        } catch (IOError e) {
            debug ("Failed to register legacy interface on connection: %s", e.message);
        }
    }

    private void on_name_lost (DBusConnection? connection) {
    }
}

