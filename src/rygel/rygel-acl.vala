/*
 * Copyright (C) 2014 Jens Georg <mail@jensge.org>
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.Acl : GLib.Object, GUPnP.Acl
{
    private DBusAclProvider provider;
    private Configuration configuration;
    private bool fallback_policy;

    public override void constructed () {
        base.constructed ();

        Bus.watch_name (BusType.SESSION,
                        DBusAclProvider.SERVICE_NAME,
                        BusNameWatcherFlags.AUTO_START,
                        this.on_name_appeared,
                        this.on_name_vanished);

        this.configuration = MetaConfig.get_default ();
        this.fallback_policy = true;
        this.update_fallback_policy ();

        this.configuration.setting_changed.connect ( (s, k) => {
            if (s == "general" && k == "acl-fallback-policy") {
                this.update_fallback_policy ();
            }
        });
     }

    /**
     * Whether this provider supports sync access.
     *
     * If we do not have a DBus provider (yet) there is no need to
     * artificially delay the fall-back policy answer.
     */
    public bool can_sync () { return this.provider == null; }

    public bool is_allowed (GUPnP.Device? device,
                            GUPnP.Service? service,
                            string         path,
                            string         address,
                            string?        agent) {
        if (this.provider == null) {
            return this.fallback_policy;
        } else {
            assert_not_reached ();
        }
    }

    public async bool is_allowed_async (GUPnP.Device? device,
                                        GUPnP.Service? service,
                                        string path,
                                        string address,
                                        string? agent,
                                        GLib.Cancellable? cancellable)
                                        throws GLib.Error {
        if (this.provider == null) {
            Idle.add ( () => { is_allowed_async.callback (); return false; });
            yield;

            return this.fallback_policy;
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
                                                     agent ?? "");
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
            warning (_("Error creating D-Bus proxy for ACL: %s"),
                     error.message);
        }
    }

    private void on_name_vanished (DBusConnection? connection, string name) {
        this.provider = null;
    }

    private void update_fallback_policy () {
        try {
            this.fallback_policy = this.configuration.get_bool
                                        ("general",
                                         "acl-fallback-policy");
            debug ("Found ACL fallback policy “%s”",
                   this.fallback_policy ? "allow" : "deny");
        } catch (Error error) {
            if (this.fallback_policy) {
                message (_("No ACL fallback policy found. Using “allow”"));
            } else {
                message (_("No ACL fallback policy found. Using “deny”"));
            }
        }
    }
}
