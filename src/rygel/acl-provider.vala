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

internal class Rygel.Acl.Provider : DBusAclProvider, Object {
    private Storage storage;

    public override void constructed () {
        base.constructed ();
        this.storage = new Storage ();
    }

    public async bool is_allowed (GLib.HashTable<string, string> device,
                                  GLib.HashTable<string, string> service,
                                  string path,
                                  string address,
                                  string? agent)
                                  throws DBusError, IOError {

        Idle.add (() => { is_allowed.callback (); return false; });
        yield;


        if (device.size () == 0 || service.size () == 0) {
            message ("Nothing to decide on, passing true");

            return true;
        }

        message ("%s from %s is trying to access %s. Allow?",
                 agent, address, device["FriendlyName"]);

        if (path.has_prefix ("/Event")) {
            message ("Trying to subscribe to events of %s on %s",
                     service["Type"], device["FriendlyName"]);
        } else if (path.has_prefix ("/Control")) {
            message ("Trying to access control of %s on %s",
                     service["Type"], device["FriendlyName"]);
        } else {
            return true;
        }

        return true;
    }

    private void on_bus_aquired (DBusConnection connection) {
        try {
            debug ("Trying to register ourselves at path %s",
                   DBusAclProvider.OBJECT_PATH);
            connection.register_object (DBusAclProvider.OBJECT_PATH,
                                        this as DBusAclProvider);
            debug ("Success.");
        } catch (IOError error) {
            warning (_("Failed to register service: %s"), error.message);
        }
    }

    public void register () {
        debug ("Trying to aquire name %s on session DBus",
               DBusAclProvider.SERVICE_NAME);
        Bus.own_name (BusType.SESSION,
                      DBusAclProvider.SERVICE_NAME,
                      BusNameOwnerFlags.NONE,
                      this.on_bus_aquired,
                      () => {},
                      () => { warning (_("Could not aquire bus name %s"),
                                       DBusAclProvider.SERVICE_NAME);
                      });
    }

    public int run () {
        message (_("Rygel ACL Provider v%s starting."),
                 BuildConfig.PACKAGE_VERSION);
        MainLoop loop = new MainLoop ();
        this.register ();
        loop.run ();
        message (_("Rygel ACL Provider done."));

        return 0;
    }

    public static int main (string[] args) {
        return new Provider ().run ();
    }
}
