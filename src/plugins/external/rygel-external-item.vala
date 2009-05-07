/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
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

using Rygel;
using GUPnP;
using DBus;

/**
 * Represents External item.
 */
public class Rygel.ExternalItem : MediaItem {
    private static string PROPS_IFACE = "org.freedesktop.DBus.Properties";
    private static string OBJECT_IFACE = "org.Rygel.MediaObject1";
    private static string ITEM_IFACE = "org.Rygel.MediaItem1";

    public ExternalItem (string         service_name,
                         string         object_path,
                         MediaContainer parent)
                         throws GLib.Error {
        base (object_path,
              parent,
              "Unknown",        /* Title Unknown at this point */
              "Unknown");       /* UPnP Class Unknown at this point */

        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        dynamic DBus.Object props = connection.get_object (service_name,
                                                           object_path,
                                                           PROPS_IFACE);

        Value value;
        props.Get (OBJECT_IFACE, "display-name", out value);
        this.title = value.get_string ();

        props.Get (ITEM_IFACE, "type", out value);
        string type = value.get_string ();
        if (type == "audio") {
            this.upnp_class = MediaItem.AUDIO_CLASS;
        } else if (type == "music") {
            this.upnp_class = MediaItem.MUSIC_CLASS;
        } else if (type == "video") {
            this.upnp_class = MediaItem.VIDEO_CLASS;
        } else {
            this.upnp_class = MediaItem.IMAGE_CLASS;
        }

        props.Get (ITEM_IFACE, "mime-type", out value);
        this.mime_type = value.get_string ();

        props.Get (ITEM_IFACE, "urls", out value);
        string[] uris = (string[]) value.get_boxed ();

        foreach (var uri in uris) {
            this.uris.add (uri);
        }
    }
}

