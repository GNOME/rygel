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

using Rygel;
using GUPnP;
using DBus;

/**
 * Represents External item.
 */
public class Rygel.ExternalItem : MediaItem {
    private static string PROPS_IFACE = "org.freedesktop.DBus.Properties";
    private static string OBJECT_IFACE = "org.gnome.UPnP.MediaObject1";
    private static string ITEM_IFACE = "org.gnome.UPnP.MediaItem1";

    public ExternalItem (string            object_path,
                         ExternalContainer parent)
                         throws GLib.Error {
        base (object_path,
              parent,
              "Unknown",        /* Title Unknown at this point */
              "Unknown");       /* UPnP Class Unknown at this point */

        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        dynamic DBus.Object props = connection.get_object (parent.service_name,
                                                           object_path,
                                                           PROPS_IFACE);

        HashTable<string,Value?> object_props = props.GetAll (OBJECT_IFACE);

        var value = object_props.lookup ("DisplayName");
        this.title = parent.substitute_keywords (value.get_string ());

        HashTable<string,Value?> item_props;
        props.GetAll (ITEM_IFACE, out item_props);

        value = item_props.lookup ("Type");
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

        value = item_props.lookup ("MIMEType");
        this.mime_type = value.get_string ();

        value = item_props.lookup ("URLs");
        weak string[] uris = (string[]) value.get_boxed ();

        for (var i = 0; uris[i] != null; i++) {
            var tmp = uris[i].replace ("@ADDRESS@", parent.host_ip);

            this.uris.add (tmp);
        }

        // Optional properties
        //
        // FIXME: Handle:
        //
        // MeidaItem1.Genre
        // MediaItem1.Thumbnail
        // MediaItem1.AlbumArt
        //

        value = item_props.lookup ("DLNAProfile");
        if (value != null) {
            this.dlna_profile = value.get_string ();
        }

        value = item_props.lookup ("Size");
        if (value != null) {
            this.size = value.get_int ();
        }

        value = item_props.lookup ("Artist");
        if (value != null) {
            this.author = value.get_string ();
        }

        value = item_props.lookup ("Album");
        if (value != null) {
            this.album = value.get_string ();
        }

        value = item_props.lookup ("Date");
        if (value != null) {
            this.date = value.get_string ();
        }

        // Properties specific to video and audio/music

        value = item_props.lookup ("Duration");
        if (value != null) {
            this.duration = value.get_int ();
        }

        value = item_props.lookup ("Bitrate");
        if (value != null) {
            this.bitrate = value.get_int ();
        }

        value = item_props.lookup ("SampleRate");
        if (value != null) {
            this.sample_freq = value.get_int ();
        }

        value = item_props.lookup ("BitsPerSample");
        if (value != null) {
            this.bits_per_sample = value.get_int ();
        }

        // Properties specific to video and image

        value = item_props.lookup ("Width");
        if (value != null) {
            this.width = value.get_int ();
        }

        value = item_props.lookup ("Height");
        if (value != null) {
            this.height = value.get_int ();
        }

        value = item_props.lookup ("ColorDepth");
        if (value != null) {
            this.color_depth = value.get_int ();
        }
    }
}

