/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
 *          Jens Georg <jensg@openismus.com>
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
using Gst;

/**
 * Abstract Tracker item factory.
 */
public abstract class Rygel.Tracker.ItemFactory {
    protected enum Metadata {
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

    private DLNADiscoverer discoverer;

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

        // FIXME: In order to work around bug#647575, we take mime-type from
        //        gupnp-dlna rather than Tracker.
        this.discoverer = new DLNADiscoverer ((ClockTime) SECOND, true, true);

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

    public abstract MediaItem create (string          id,
                                      string          uri,
                                      SearchContainer parent,
                                      string[]        metadata)
                                      throws GLib.Error;

    protected void set_ref_id (MediaItem item, string prefix) {
        if (item.id.has_prefix (prefix)) {
            return;
        }

        var split_id = item.id.split (",");
        if (split_id.length != 2) {
            return;
        }

        item.ref_id = prefix + "," + split_id[1];
    }

    protected virtual void set_metadata (MediaItem item,
                                         string    uri,
                                         string[]  metadata) throws GLib.Error {
        if (metadata[Metadata.TITLE] != "")
            item.title = metadata[Metadata.TITLE];
        else
            /* If title wasn't provided, use filename instead */
            item.title = metadata[Metadata.FILE_NAME];

        if (metadata[Metadata.SIZE] != "")
            item.size = int64.parse (metadata[Metadata.SIZE]);
        else
            // If its in tracker store and size is unknown, it most probably
            // means the size is 0 (i-e a place-holder empty item that we
            // created).
            item.size = 0;

        item.place_holder = bool.parse (metadata[Metadata.PLACE_HOLDER]);

        if (metadata[Metadata.DATE] != "")
            item.date = metadata[Metadata.DATE];

        var profile = null as DLNAProfile;
        if (metadata[Metadata.DLNA_PROFILE] != "") {
            item.dlna_profile = metadata[Metadata.DLNA_PROFILE];
            profile = this.discoverer.get_profile (item.dlna_profile);
        }

        if (profile != null) {
            item.mime_type = profile.mime;
        } else {
            item.mime_type = metadata[Metadata.MIME];
        }

        item.add_uri (uri);
    }
}

