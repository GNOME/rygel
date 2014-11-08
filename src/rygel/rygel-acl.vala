/*
 * Copyright (C) 2014 Jens Georg <mail@jensge.org>
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.Acl : GLib.Object, GUPnP.Acl
{
    private DBusAclProvider provider;

    public Acl () {
        Bus.watch_name (BusType.SESSION,
                        DBusAclProvider.SERVICE_NAME,
                        BusNameWatcherFlags.AUTO_START,
                        this.on_name_appeared,
                        this.on_name_vanished);
    }

    public bool can_sync () { return false; }

    public bool is_allowed (GUPnP.Device? device,
                            GUPnP.Service? service,
                            string         path,
                            string         address,
                            string?        agent) {
        assert_not_reached ();
    }

    public async bool is_allowed_async (GUPnP.Device? device,
                                        GUPnP.Service? service,
                                        string path,
                                        string address,
                                        string? agent,
                                        GLib.Cancellable? cancellable)
                                        throws GLib.Error {
        if (this.provider == null) {
            debug ("No external provider found, allowing access…");

            return true;
        }

        debug ("Querying ACL for %s on %s by %s@%s",
               path,
               device != null ? device.udn : "none",
               agent ?? "Unknown",
               address);

        try {
            var device_hash = new HashTable<string, string> (str_hash, str_equal);

            if (device != null) {
                device_hash["FriendlyName"] = device.get_friendly_name ();
                device_hash["UDN"] = device.udn;
                device_hash["Type"] = device.device_type;
            }

            var service_hash = new HashTable<string, string> (str_hash, str_equal);
            if (service != null) {
                service_hash["Type"] = service.service_type;
            }

            var allowed = yield provider.is_allowed (device_hash,
                                                     service_hash,
                                                     path,
                                                     address,
                                                     agent);
            return allowed;
        } catch (Error error) {
            warning (_("Failed to query ACL: %s"), error.message);
        }

        return false;
    }

    private void on_name_appeared (DBusConnection connection,
                                   string         name,
                                   string         name_owner) {
        debug ("Found ACL provider %s (%s), creating object",
               name,
               name_owner);
        try {
            this.provider = Bus.get_proxy_sync (BusType.SESSION,
                                                name,
                                                DBusAclProvider.OBJECT_PATH);
        } catch (Error error) {
            warning (_("Error creating DBus proxy for ACL: %s"),
                     error.message);
        }
    }

    private void on_name_vanished (DBusConnection connection, string name) {
        this.provider = null;
    }
}
