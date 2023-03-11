/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
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

using GUPnP;

/**
 * Represents a music item.
 */
public class Rygel.MusicItem : AudioItem {
    public new const string UPNP_CLASS = "object.item.audioItem.musicTrack";

    public int track_number { get; set; default = -1; }
    public int disc_number { get; set; default = -1; }

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
        if (this.album_art != null) {
            return;
        }

        var media_art_store = MediaArtStore.get_default ();
        if (media_art_store == null) {
            return;
        }

        try {
            this.album_art = media_art_store.lookup_media_art (this);
        } catch (Error error) {
            debug ("Failed to look up album art: %s", error.message);
        };
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        if (!(media_object is MusicItem)) {
           return 1;
        }

        var item = media_object as MusicItem;

        switch (property) {
        case "upnp:originalTrackNumber":
            return this.compare_int_props (this.track_number,
                                           item.track_number);
        case "upnp:originalDiscNumber":
            return this.compare_int_props (this.disc_number,
                                           item.disc_number);
        default:
            return base.compare_by_property (item, property);
        }
    }

    internal override void apply_didl_lite (DIDLLiteObject didl_object) {
        base.apply_didl_lite (didl_object);

        this.track_number = didl_object.track_number;
        //FIXME: this.disc_number = didl_object.disc_number;

        if (didl_object.album_art != null && didl_object.album_art.length > 0) {
            if (this.album_art == null)
                this.album_art = new Thumbnail ();
            this.album_art.uri = didl_object.album_art;
        } else if (this.album_art != null)
            this.album_art = null;
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer http_server)
                                                 throws Error {
        var didl_item = base.serialize (serializer, http_server);

        if (this.track_number >= 0) {
            didl_item.track_number = this.track_number;

            // Hack for now, probably should move to gupnp-av
            Xml.Node *node = didl_item.xml_node;
            Xml.Ns *ns = null;

            bool strict_sharing = false;

            try {
                strict_sharing = MetaConfig.get_default().get_bool ("general", "strict-dlna");
            } catch (Error err) {}

            if (strict_sharing) {
                ns = XMLUtils.get_namespace(node, "http://www.rygel-project.org/ns/", "rygel");
            } else {
                ns = didl_item.get_upnp_namespace ();
            }

            node->new_child (ns, "originalDiscNumber", this.disc_number.to_string ());
        }

        if (!this.place_holder && this.album_art != null) {
            var protocol = this.get_protocol_for_uri (this.album_art.uri);

            // Use the existing URI if the server is local or a non-internal
            // file uri is set
            if (http_server.is_local () || protocol != "internal") {
                didl_item.album_art = this.album_art.uri;
            } else {
                // Create a http uri for the album art that our server can process
                string http_uri = http_server.create_uri_for_object (this,
                                                                   0,
                                                                   -1,
                                                                   null);
                didl_item.album_art = MediaFileItem.address_regex.replace_literal
                                            (http_uri,
                                             -1,
                                             0,
                                             http_server.context.address.to_string ());
            }
        }

        return didl_item;
    }
}
