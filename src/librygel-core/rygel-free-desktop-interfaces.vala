/*
 * Copyright (C) 2009,2010 Nokia Corporation.
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

namespace FreeDesktop {
    public const string DBUS_SERVICE = "org.freedesktop.DBus";
    public const string DBUS_OBJECT_PATH = "/org/freedesktop/DBus";
}

[DBus (name = "org.freedesktop.DBus")]
public interface FreeDesktop.DBusObject: Object {
    public abstract signal void name_owner_changed (string name,
                                                    string old_owner,
                                                    string new_owner);

    public abstract async string[] list_names () throws DBusError;
    public abstract async string[] list_activatable_names () throws DBusError;
}

[DBus (name = "org.freedesktop.DBus.Properties")]
public interface FreeDesktop.Properties: Object {
    public abstract async HashTable<string,Variant> get_all (string iface)
                                                             throws DBusError;
}
