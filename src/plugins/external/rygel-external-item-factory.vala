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
public class Rygel.External.ItemFactory {
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
        if (parent is DummyContainer) {
            item.parent_ref = parent;
        }

        item.mime_type = this.get_string (props, "MIMEType");

        var value = props.lookup ("URLs");
        var uris = (string[]) value;

        for (var i = 0; uris[i] != null; i++) {
            var tmp = uris[i].replace ("@ADDRESS@", host_ip);

            item.add_uri (tmp, null);
        }

        // Optional properties

        item.dlna_profile  = this.get_string (props, "DLNAProfile");

        value = props.lookup ("Size");
        if (value != null) {
            item.size = (int64) value;
        }

        item.author = this.get_string (props, "Artist");
        item.album = this.get_string (props, "Album");
        item.genre = this.get_string (props, "Genre");
        item.date = this.get_string (props, "Date");

        // Properties specific to video and audio/music

        item.duration = this.get_int (props, "Duration");
        item.bitrate = this.get_int (props, "Bitrate");
        item.sample_freq = this.get_int (props, "SampleRate");
        item.bits_per_sample = this.get_int (props, "BitsPerSample");

        value = props.lookup ("AlbumArt");
        if (value != null) {
            var cover_factory = new AlbumArtFactory ();
            var album_art = yield cover_factory.create ((string) value,
                                                        service_name,
                                                        host_ip);
            item.thumbnails.add (album_art);
        }

        // Properties specific to video and image

        item.width = this.get_int (props, "Width");
        item.height = this.get_int (props, "Height");
        item.color_depth = this.get_int (props, "ColorDepth");
        item.pixel_width = this.get_int (props, "PixelWidth");
        item.pixel_height = this.get_int (props, "PixelHeight");

        value = props.lookup ("Thumbnail");
        if (value != null) {
            var factory = new ThumbnailFactory ();
            var thumbnail = yield factory.create ((string) value,
                                                  service_name,
                                                  host_ip);
            item.thumbnails.add (thumbnail);
        }

        return item;
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

