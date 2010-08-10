/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
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
using FreeDesktop;

/**
 * Factory for thumbnail from external plugins.
 */
public class Rygel.External.ThumbnailFactory {
    public async Thumbnail create (string service_name,
                                   string object_path,
                                   string host_ip)
                                   throws GLib.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        var props = connection.get_object (service_name,
                                           object_path)
                                           as Properties;

        var item_props = yield props.get_all (MediaItemProxy.IFACE);

        var thumbnail = new Thumbnail ();

        thumbnail.mime_type = this.get_string (item_props, "MIMEType");
        thumbnail.dlna_profile = this.get_string (item_props, "DLNAProfile");
        thumbnail.width = this.get_int (item_props, "Width");
        thumbnail.height = this.get_int (item_props, "Height");
        thumbnail.depth = this.get_int (item_props, "ColorDepth");

        var value = item_props.lookup ("URLs");
        var uris = (string[]) value;
        if (uris != null && uris[0] != null) {
            thumbnail.uri = uris[0].replace ("@ADDRESS@", host_ip);
        }

        value = item_props.lookup ("Size");
        if (value != null) {
            thumbnail.size = (int64) value;
        }

        return thumbnail;
    }

    private string? get_string (HashTable<string,Value?> props, string prop) {
        var value = props.lookup (prop);

        if (value != null) {
            return (string) value;
        } else {
            return null;
        }
    }

    private int get_int (HashTable<string,Value?> props, string prop) {
        var value = props.lookup (prop);

        if (value != null) {
            return (int) value;
        } else {
            return -1;
        }
    }
}

