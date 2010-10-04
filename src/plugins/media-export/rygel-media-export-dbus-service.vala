/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
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

[DBus (name = "org.gnome.Rygel.MediaExport1")]
public class Rygel.MediaExport.DBusService : Object {
    private const string RYGEL_MEDIA_EXPORT_PATH =
                                        "/org/gnome/Rygel/MediaExport1";

    private RootContainer root_container;

    public DBusService (RootContainer root_container) throws GLib.Error {
        this.root_container = root_container;

        try {
            var connection = Bus.get_sync (BusType.SESSION);

            if (likely (connection != null)) {
                connection.register_object (RYGEL_MEDIA_EXPORT_PATH, this);
            }
        } catch (IOError err) {
            warning (_("Failed to attach to D-Bus session bus: %s"),
                     err.message);
        }
    }

    public void AddUri (string uri) {
        this.root_container.add_uri (uri);
    }

    public void RemoveUri (string uri) {
        this.root_container.remove_uri (uri);
    }

    public string[] GetUris () {
        return this.root_container.get_dynamic_uris ();
    }
}
