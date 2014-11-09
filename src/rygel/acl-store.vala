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

enum Rygel.Acl.Policy {
    ALLOW,
    DENY
}

enum Rygel.Acl.Action {
    UNKNOWN,
    EVENT_SUBSCRIPTION,
    CONTROL_ACCESS
}

internal class Rygel.Acl.Storage : Object {

    public Storage () {
        Object();
    }

    public Policy get_default_policy () {
        return Policy.ALLOW;
    }

    public async bool is_allowed (GLib.HashTable<string, string> device,
                                  GLib.HashTable<string, string> service,
                                  string path,
                                  string address,
                                  string? agent) {
        Idle.add (() => { is_allowed.callback (); return false; });
        yield;


        if (this.get_default_policy () == Policy.ALLOW) {
            return true;
        }

        return false;
    }
}
