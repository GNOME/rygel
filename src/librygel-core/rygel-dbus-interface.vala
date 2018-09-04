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
public interface Rygel.DBusInterface : Object {
    public const string SERVICE_NAME = "org.gnome.Rygel1";
    public const string OBJECT_PATH = "/org/gnome/Rygel1";

    public abstract void shutdown () throws IOError, DBusError;
}

[DBus (name = "org.gnome.Rygel1.AclProvider1")]
public interface Rygel.DBusAclProvider : Object {
    public const string SERVICE_NAME = "org.gnome.Rygel1.AclProvider1";
    public const string OBJECT_PATH = "/org/gnome/Rygel1/AclProvider1";

    public abstract async bool is_allowed (GLib.HashTable<string, string> device,
                                           GLib.HashTable<string, string> service,
                                           string                         path,
                                           string                         address,
                                           string?                        agent)
                                           throws DBusError, IOError;
}
