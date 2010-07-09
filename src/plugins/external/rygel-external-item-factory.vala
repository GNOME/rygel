/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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

using GUPnP;
using DBus;
using FreeDesktop;

/**
 * Creates item for external plugins.
 */
public class Rygel.ExternalItemFactory {
    public async MediaItem create (string                   id,
                                   string                   type,
                                   string                   title,
                                   HashTable<string,Value?> props,
                                   string                   service_name,
                                   string                   host_ip,
                                   MediaContainer           parent)
                                   throws GLib.Error {
        string upnp_class;

        if (type.has_prefix ("audio")) {
            upnp_class = MediaItem.AUDIO_CLASS;
        } else if (type.has_prefix ("music")) {
            upnp_class = MediaItem.MUSIC_CLASS;
        } else if (type.has_prefix ("video")) {
            upnp_class = MediaItem.VIDEO_CLASS;
        } else {
            upnp_class = MediaItem.IMAGE_CLASS;
        }

        var item = new MediaItem (id, parent, title, upnp_class);

        var value = props.lookup ("MIMEType");
        item.mime_type = value.get_string ();

        // FIXME: Get this value through the props until bug#602003 is fixed
        // value = props.lookup ("URLs");
        var connection = DBus.Bus.get (DBus.BusType.SESSION);
        var item_iface = connection.get_object (service_name, id)
                         as ExternalMediaItemProxy;
        string[] uris = item_iface.urls;

        for (var i = 0; uris[i] != null; i++) {
            var tmp = uris[i].replace ("@ADDRESS@", host_ip);

            item.add_uri (tmp, null);
        }

        // Optional properties
        //
        // FIXME: Handle:
        //
        // MeidaItem1.Genre
        // MediaItem1.AlbumArt
        //

        value = props.lookup ("DLNAProfile");
        if (value != null) {
            item.dlna_profile = value.get_string ();
        }

        value = props.lookup ("Size");
        if (value != null) {
            item.size = value.get_int ();
        }

        value = props.lookup ("Artist");
        if (value != null) {
            item.author = value.get_string ();
        }

        value = props.lookup ("Album");
        if (value != null) {
            item.album = value.get_string ();
        }

        value = props.lookup ("Date");
        if (value != null) {
            item.date = value.get_string ();
        }

        // Properties specific to video and audio/music

        value = props.lookup ("Duration");
        if (value != null) {
            item.duration = value.get_int ();
        }

        value = props.lookup ("Bitrate");
        if (value != null) {
            item.bitrate = value.get_int ();
        }

        value = props.lookup ("SampleRate");
        if (value != null) {
            item.sample_freq = value.get_int ();
        }

        value = props.lookup ("BitsPerSample");
        if (value != null) {
            item.bits_per_sample = value.get_int ();
        }

        // Properties specific to video and image

        value = props.lookup ("Width");
        if (value != null) {
            item.width = value.get_int ();
        }

        value = props.lookup ("Height");
        if (value != null) {
            item.height = value.get_int ();
        }

        value = props.lookup ("ColorDepth");
        if (value != null) {
            item.color_depth = value.get_int ();
        }

        value = props.lookup ("PixelWidth");
        if (value != null) {
            item.pixel_width = value.get_int ();
        }

        value = props.lookup ("PixelHeight");
        if (value != null) {
            item.pixel_height = value.get_int ();
        }

        value = props.lookup ("Thumbnail");
        if (value != null) {
            var factory = new ExternalThumbnailFactory ();
            var thumbnail = yield factory.create (value.get_string (),
                                                  service_name,
                                                  host_ip);
            item.thumbnails.add (thumbnail);
        }

        return item;
    }
}

