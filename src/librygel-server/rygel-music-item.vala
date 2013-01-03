/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

/**
 * Represents a music item.
 */
public class Rygel.MusicItem : AudioItem {
    public new const string UPNP_CLASS = "object.item.audioItem.musicTrack";

    public string artist { get; set; }
    public string album { get; set; }
    public string genre { get; set; }
    public int track_number { get; set; default = -1; }

    public Thumbnail album_art { get; set; }

    public MusicItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = MusicItem.UPNP_CLASS) {
        Object (id : id,
                parent : parent,
                title : title,
                upnp_class : upnp_class);
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
                didl_item.album_art = this.album_art.uri;
            }
        }
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        if (!(media_object is MusicItem)) {
           return 1;
        }

        var item = media_object as MusicItem;

        switch (property) {
        case "dc:artist":
            return this.compare_string_props (this.artist, item.artist);
        case "upnp:album":
            return this.compare_string_props (this.album, item.album);
        case "upnp:originalTrackNumber":
             return this.compare_int_props (this.track_number,
                                            item.track_number);
        default:
            return base.compare_by_property (item, property);
        }
    }

    internal override void apply_didl_lite (DIDLLiteObject didl_object) {
        base.apply_didl_lite (didl_object);

        this.artist = this.get_first (didl_object.get_artists ());
        this.track_number = didl_object.track_number;
        this.album = didl_object.album;
        this.genre = didl_object.genre;
        // TODO: Not sure about it.
        //this.album_art.uri = didl_object.album_art
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer http_server)
                                                 throws Error {
        var didl_item = base.serialize (serializer, http_server);

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

        if (didl_item.album_art != null) {
            didl_item.album_art = MediaItem.address_regex.replace_literal
                                        (didl_item.album_art,
                                         -1,
                                         0,
                                         http_server.context.host_ip);
        }

        return didl_item;
    }

    internal override void add_proxy_resources (HTTPServer   server,
                                                DIDLLiteItem didl_item)
                                                throws Error {
        base.add_proxy_resources (server, didl_item);

        // Album-art URI comes in the end
        if (!this.place_holder &&
            this.album_art != null &&
            server.need_proxy (this.album_art.uri)) {
            didl_item.album_art = server.create_uri_for_item (this,
                                                              0,
                                                              -1,
                                                              null,
                                                              null);
        }
    }

    private string get_first (GLib.List<DIDLLiteContributor>? contributors) {
        if (contributors != null) {
            return contributors.data.name;
        }

        return "";
    }

}
