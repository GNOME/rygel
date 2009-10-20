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

using FreeDesktop;

public class Rygel.ExternalPlugin : Rygel.Plugin {
    private static string ITEM_IFACE = "org.gnome.UPnP.MediaItem1";

    public string service_name;
    public string root_object;

    public static async ExternalPlugin create (DBus.Connection connection,
                                               string          service_name) {
        // org.gnome.UPnP.MediaServer1.NAME => /org/gnome/UPnP/MediaServer1/NAME
        var root_object = "/" + service_name.replace (".", "/");

        // Create proxy to MediaObject iface to get the display name through
        var root_container = connection.get_object (service_name,
                                                    root_object)
                                                    as ExternalMediaContainer;

        var icon = yield fetch_icon (connection, service_name, root_container);

        return new ExternalPlugin (service_name,
                                   root_container.display_name,
                                   root_object,
                                   icon);
    }

    public ExternalPlugin (string    service_name,
                           string    title,
                           string    root_object,
                           IconInfo? icon) {
        base.MediaServer (service_name,
                          title,
                          typeof (ExternalContentDir));

        this.service_name = service_name;
        this.root_object = root_object;
        if (icon != null) {
            this.add_icon (icon);
        }
    }

    public static async IconInfo? fetch_icon (
                                        DBus.Connection        connection,
                                        string                 service_name,
                                        ExternalMediaContainer root_container) {
        if (root_container.icon == null)
            return null;

        var props = connection.get_object (service_name,
                                           root_container.icon)
                                           as Properties;

        HashTable<string,Value?> item_props;
        try {
            item_props = yield props.get_all (ITEM_IFACE);
        } catch (DBus.Error err) {
            warning ("Error fetching icon properties from %s", service_name);

            return null;
        }

        var value = item_props.lookup ("MIMEType");
        var icon = new IconInfo (value.get_string ());

        value = item_props.lookup ("URLs");
        weak string[] uris = (string[]) value.get_boxed ();
        if (uris != null && uris[0] != null) {
            icon.uri = uris[0];
        }

        value = item_props.lookup ("Size");
        if (value != null) {
            icon.size = value.get_int ();
        }

        value = item_props.lookup ("Width");
        if (value != null) {
            icon.width = value.get_int ();
        }

        value = item_props.lookup ("Height");
        if (value != null) {
            icon.height = value.get_int ();
        }

        value = item_props.lookup ("ColorDepth");
        if (value != null) {
            icon.depth = value.get_int ();
        }

        return icon;
    }
}
