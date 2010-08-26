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

using DBus;

[DBus (name = "org.freedesktop.DBus")]
public interface FreeDesktop.DBusObject: DBus.Object {
    public abstract signal void name_owner_changed (string name,
                                                    string old_owner,
                                                    string new_owner);

    public abstract async string[] list_names () throws DBus.Error;
    public abstract async string[] list_activatable_names () throws DBus.Error;
}

[DBus (name = "org.freedesktop.DBus.Properties")]
public interface FreeDesktop.Properties: DBus.Object {
    public abstract async HashTable<string,Value?> get_all (string iface)
                                                            throws DBus.Error;
    public abstract signal void properties_changed
                                        (string                   iface,
                                         HashTable<string,Value?> changed,
                                         string[]                 invalidated);
}

