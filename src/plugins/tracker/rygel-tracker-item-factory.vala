/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
 *          Jens Georg <jensg@openismus.com>
 *          Doug Galligan <doug@sentosatech.com>
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

using Gee;
using GUPnP;
using Tracker;

/**
 * Abstract Tracker item factory.
 */
public abstract class Rygel.Tracker.ItemFactory {
    protected enum Metadata {
        TRACKER_ID,
        URL,
        PLACE_HOLDER,
        FILE_NAME,
        TITLE,
        DLNA_PROFILE,
        MIME,
        SIZE,
        DATE,

        LAST_KEY
    }

    public string category;
    public string category_iri;
    public string upnp_class;
    public string upload_dir;

    public ArrayList<string> properties;

    public ItemFactory (string  category,
                        string  category_iri,
                        string  upnp_class,
                        string? upload_dir) {
        this.category = category;
        this.category_iri = category_iri;
        this.upnp_class = upnp_class;
        this.upload_dir = upload_dir;

        message ("Using %s as upload directory for %s",
                 upload_dir == null ? "none" : upload_dir,
                 upnp_class);

        this.properties = new ArrayList<string> ();

        // These must be the same order as enum Metadata
        this.properties.add ("res");
        this.properties.add ("place_holder");
        this.properties.add ("fileName");
        this.properties.add ("dc:title");
        this.properties.add ("dlnaProfile");
        this.properties.add ("mimeType");
        this.properties.add ("res@size");
        this.properties.add ("date");
    }

    public abstract MediaFileItem create (string          id,
                                          string          uri,
                                          SearchContainer parent,
                                          Sparql.Cursor   metadata)
                                          throws GLib.Error;

    protected void set_ref_id (MediaFileItem item, string prefix) {
        if (item.id.has_prefix (prefix)) {
            return;
        }

        var split_id = item.id.split (",");
        if (split_id.length != 2) {
            return;
        }

        item.ref_id = prefix + "," + split_id[1];
    }

    protected virtual void set_metadata (MediaFileItem item,
                                         string        uri,
                                         Sparql.Cursor metadata)
                                         throws GLib.Error {
        if (metadata.is_bound (Metadata.TITLE)) {
            item.title = metadata.get_string (Metadata.TITLE);
        } else {
            /* If title wasn't provided, use filename instead */
            item.title = metadata.get_string (Metadata.FILE_NAME);
        }

        if (metadata.is_bound (Metadata.SIZE)) {
            item.size = metadata.get_integer (Metadata.SIZE);
        } else {
            // If its in tracker store and size is unknown, it most probably
            // means the size is 0 (i-e a place-holder empty item that we
            // created).
            item.size = 0;
        }

        item.place_holder = metadata.get_boolean (Metadata.PLACE_HOLDER);

        if (metadata.is_bound (Metadata.DATE)) {
            item.date = metadata.get_string (Metadata.DATE);
        }

        if (metadata.is_bound (Metadata.DLNA_PROFILE)) {
            item.dlna_profile = metadata.get_string (Metadata.DLNA_PROFILE);
        }

        if (metadata.is_bound (Metadata.MIME)) {
            item.mime_type = metadata.get_string (Metadata.MIME);
        }

        item.add_uri (uri);
    }
}

