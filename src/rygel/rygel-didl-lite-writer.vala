/*
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

using GUPnP;
using Gee;

internal errordomain Rygel.DIDLLiteWriterError {
    UNSUPPORTED_OBJECT
}

/**
 * Responsible for serializing media objects.
 */
internal class Rygel.DIDLLiteWriter : GUPnP.DIDLLiteWriter {
    private Rygel.HTTPServer http_server;

    public DIDLLiteWriter (HTTPServer http_server) {
        this.http_server = http_server;
    }

    public void serialize (MediaObject media_object) throws Error {
        if (media_object is MediaItem) {
            this.serialize_item ((MediaItem) media_object);
        } else if (media_object is MediaContainer) {
            this.serialize_container ((MediaContainer) media_object);
        } else {
            throw new DIDLLiteWriterError.UNSUPPORTED_OBJECT (
                "Unable to serialize unsupported object");
        }
    }

    private void serialize_item (MediaItem item) throws Error {
        var didl_item = this.add_item ();

        didl_item.id = item.id;
        if (item.parent != null) {
            didl_item.parent_id = item.parent.id;
        } else {
            didl_item.parent_id = "0";
        }

        didl_item.restricted = false;

        didl_item.title = item.title;
        didl_item.upnp_class = item.upnp_class;
        if (item.author != null && item.author != "") {
            didl_item.creator = item.author;

            if (item.upnp_class.has_prefix (MediaItem.VIDEO_CLASS)) {
                didl_item.author = item.author;
            } else if (item.upnp_class.has_prefix (MediaItem.MUSIC_CLASS)) {
                didl_item.artist = item.author;
            }
        }

        if (item.track_number >= 0) {
            didl_item.track_number = item.track_number;
        }

        if (item.album != null && item.album != "") {
            didl_item.album = item.album;
        }

        if (item.date != null && item.date != "") {
            didl_item.date = item.date;
        }

        if (item.place_holder) {
            this.http_server.add_proxy_resource (didl_item, item);
        } else {
            // Add the transcoded/proxy URIs first
            this.http_server.add_resources (didl_item, item);

            // then original URIs
            bool internal_allowed;
            internal_allowed = this.http_server.context.interface == "lo" ||
                               this.http_server.context.host_ip == "127.0.0.1";
            item.add_resources (didl_item, internal_allowed);
        }
    }

    private void serialize_container (MediaContainer container) throws Error {
        var didl_container = this.add_container ();
        if (container.parent != null) {
            didl_container.parent_id = container.parent.id;
        } else {
            didl_container.parent_id = "-1";
        }

        didl_container.id = container.id;
        didl_container.title = container.title;
        didl_container.child_count = container.child_count;
        didl_container.upnp_class = container.upnp_class;
        didl_container.restricted = container.uris.size <= 0;
        didl_container.searchable = true;
    }
}
