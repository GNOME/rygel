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

using Rygel.External.FreeDesktop;

public class Rygel.External.IconFactory {
    private static string ITEM_IFACE = "org.gnome.UPnP.MediaItem2";

    public async IconInfo? create (string                    service_name,
                                   HashTable<string,Variant> container_props)
                                   throws IOError, DBusError {
        var value = container_props.lookup ("Icon");
        if (value == null) {
            // Seems no icon is provided, nevermind
            return null;
        }

        var icon_path = (string) value;
        Properties props = yield Bus.get_proxy
                                        (BusType.SESSION,
                                         service_name,
                                         icon_path,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

        var item_props = yield props.get_all (ITEM_IFACE);

        return this.create_from_props (item_props);
    }

    private IconInfo? create_from_props (HashTable<string,Variant> props) {
        var mime_type = (string) props.lookup ("MIMEType");
        var icon = new IconInfo (mime_type, this.get_ext_for_mime (mime_type));

        var uris = (string[]) props.lookup ("URLs");
        if (uris != null && uris[0] != null) {
            icon.uri = uris[0];
        }

        var value = props.lookup ("Size");
        if (value != null) {
            icon.size = (int64) value;
        }

        icon.width = this.get_int (props, "Width");
        icon.height = this.get_int (props, "Height");
        icon.depth = this.get_int (props, "ColorDepth");

        return icon;
    }

    private string get_ext_for_mime (string mime_type) {
      if (mime_type == "image/jpeg") {
            return "jpg";
      } else if (mime_type == "image/gif") {
            return "gif";
      } else {
            return "png"; // Assume PNG
      }
    }

    private int get_int (HashTable<string,Variant> props, string prop) {
        var value = props.lookup (prop);

        if (value != null) {
            return (int) value;
        } else {
            return -1;
        }
    }
}
