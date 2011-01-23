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

using FreeDesktop;

[DBus (name = "org.gnome.Rygel1")]
public class Rygel.DBusService : Object, DBusInterface {
    private Main main;
    private uint connection_id;

    public DBusService (Main main) throws IOError {
        this.main = main;

        DBusObject bus = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         DBUS_SERVICE,
                                         DBUS_OBJECT,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

        // try to register service in session bus
        if (bus.request_name (DBusInterface.SERVICE_NAME, 0) !=
            DBusRequestNameReply.PRIMARY_OWNER) {
            warning ("Failed to start D-Bus service  name '%s' already taken",
                     DBusInterface.SERVICE_NAME);
        } else {
            var conn = Bus.get_sync (BusType.SESSION);

            this.connection_id = conn.register_object
                                        (DBusInterface.OBJECT_PATH, this);
        }
    }

    internal void unpublish () {
        try {
            var conn = Bus.get_sync (BusType.SESSION);
            conn.unregister_object (this.connection_id);
        } catch (IOError error) { }
    }

    public void shutdown () throws IOError {
        this.main.exit (0);
    }
}

