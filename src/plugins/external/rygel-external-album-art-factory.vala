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
public class Rygel.External.AlbumArtFactory {
    public async Thumbnail create (string service_name,
                                   string object_path,
                                   string host_ip)
                                   throws GLib.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        var props = connection.get_object (service_name,
                                           object_path)
                                           as Properties;

        var item_props = yield props.get_all (MediaItemProxy.IFACE);

        var thumbnail = new AlbumArt ();

        var value = item_props.lookup ("MIMEType");
        thumbnail.mime_type = (string) value;

        value = item_props.lookup ("URLs");
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
}
