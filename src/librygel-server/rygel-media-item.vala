/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
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

private errordomain Rygel.MediaItemError {
    BAD_URI
}

/**
 * Abstract class representing a MediaItem
 *
 * MediaItems must live in a container and may not contain other MediaItems
 */
public abstract class Rygel.MediaItem : MediaObject {

    public string description { get; set; default = null; }

    internal override void apply_didl_lite (DIDLLiteObject didl_object) {
        base.apply_didl_lite (didl_object);

        this.creator = didl_object.get_creator ();
        this.date = didl_object.date;
        this.description = didl_object.description;
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer http_server)
                                                 throws Error {
        var didl_item = serializer.add_item ();

        didl_item.id = this.id;

        if (this.ref_id != null) {
            didl_item.ref_id = this.ref_id;
        }

        if (this.parent != null) {
            didl_item.parent_id = this.parent.id;
        } else {
            didl_item.parent_id = "0";
        }

        if (this.restricted) {
            didl_item.restricted = true;
        } else {
            didl_item.restricted = false;
            didl_item.dlna_managed = this.ocm_flags;
        }

        didl_item.title = this.title;
        didl_item.upnp_class = this.upnp_class;

        if (this.date != null) {
            didl_item.date = this.date;
        }

        if (this.creator != null && this.creator != "") {
            var creator = didl_item.add_creator ();
            creator.name = this.creator;
        }

        if (this.description != null) {
            didl_item.description = this.description;
        }

        if (this is TrackableItem) {
            didl_item.update_id = this.object_update_id;
        }

        if (this.artist != null && this.artist != "") {
            var contributor = didl_item.add_artist ();
            contributor.name = this.artist;
        }

        if (this.genre != null && this.genre != "") {
            didl_item.genre = this.genre;
        }

        return didl_item;
    }

    protected virtual ProtocolInfo get_protocol_info (string? uri,
                                                      string  protocol) {
        var protocol_info = new ProtocolInfo ();

        protocol_info.protocol = protocol;
        protocol_info.dlna_flags = DLNAFlags.DLNA_V15 |
                                   DLNAFlags.CONNECTION_STALL |
                                   DLNAFlags.BACKGROUND_TRANSFER_MODE;

        return protocol_info;
    }
}
