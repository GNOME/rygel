/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
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
using Gst;

/**
 * Represents a music item.
 */
public class Rygel.MusicItem : AudioItem {
    public new const string UPNP_CLASS = "object.item.audioItem.musicTrack";

    public string artist;
    public string album;
    public string genre;
    public int track_number = -1;

    public Thumbnail album_art;

    public MusicItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = MusicItem.UPNP_CLASS) {
        base (id, parent, title, upnp_class);
    }

    public void lookup_album_art () {
        assert (this.album_art == null);

        var media_art_store = MediaArtStore.get_default ();
        if (media_art_store == null) {
            return;
        }

        try {
            this.album_art = media_art_store.find_media_art_any (this);
        } catch (Error err) {};
    }

    internal override void add_resources (DIDLLiteItem didl_item,
                                          bool         allow_internal)
                                         throws Error {
        base.add_resources (didl_item, allow_internal);

        if (this.album_art != null) {
            var protocol = this.get_protocol_for_uri (this.album_art.uri);

            if (allow_internal || protocol != "internal") {
                album_art.add_resource (didl_item, protocol);
            }
        }
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        var item = media_object as MusicItem;

        switch (property) {
        case "dc:artist":
            return this.compare_string_props (this.artist, item.artist);
        case "upnp:album":
            return this.compare_string_props (this.album, item.album);
        default:
            return base.compare_by_property (item, property);
        }
    }

    internal override DIDLLiteItem serialize (DIDLLiteWriter writer)
                                             throws Error {
        var didl_item = base.serialize (writer);

        if (this.artist != null && this.artist != "") {
            var contributor = didl_item.add_artist ();
            contributor.name = this.artist;
        }

        if (this.track_number >= 0) {
            didl_item.track_number = this.track_number;
        }

        if (this.album != null && this.album != "") {
            didl_item.album = this.album;
        }

        if (this.genre != null && this.genre != "") {
            didl_item.genre = this.genre;
        }

        return didl_item;
    }

    internal override void add_proxy_resources (HTTPServer   server,
                                                DIDLLiteItem didl_item)
                                                throws Error {
        base.add_proxy_resources (server, didl_item);

        // Album-art URI comes in the end
        if (this.album_art != null && server.need_proxy (this.album_art.uri)) {
            var uri = album_art.uri; // Save the original URI

            album_art.uri = server.create_uri_for_item (this, 0, -1, null);
            album_art.add_resource (didl_item, server.get_protocol ());

            // Now restore the original URI
            album_art.uri = uri;
        }
    }
}
