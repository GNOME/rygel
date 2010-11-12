/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

/**
 * Abstract Tracker item factory.
 */
public abstract class Rygel.Tracker.ItemFactory {
    protected enum Metadata {
        FILE_NAME,
        TITLE,
        DLNA_PROFILE,
        MIME,
        SIZE,
        DATE,

        LAST_KEY
    }

    public string category;
    public string upnp_class;
    public string upload_dir;

    public ArrayList<ArrayList<string>> key_chains;

    public ItemFactory (string  category,
                        string  upnp_class,
                        string? upload_dir) {
        this.category = category;
        this.upnp_class = upnp_class;
        this.upload_dir = upload_dir;

        this.key_chains = new ArrayList<ArrayList<string>> ();

        for (var i = 0; i < Metadata.LAST_KEY; i++) {
            this.key_chains.add (new ArrayList<string> ());
        }

        this.key_chains[Metadata.FILE_NAME].add ("nfo:fileName");
        this.key_chains[Metadata.TITLE].add ("nie:title");
        this.key_chains[Metadata.DLNA_PROFILE].add ("nmm:dlnaProfile");
        this.key_chains[Metadata.MIME].add ("nie:mimeType");
        this.key_chains[Metadata.SIZE].add ("nfo:fileSize");
        this.key_chains[Metadata.DATE].add ("nie:contentCreated");
    }

    public abstract MediaItem create (string          id,
                                      string          uri,
                                      SearchContainer parent,
                                      string[]        metadata)
                                      throws GLib.Error;

    protected virtual void set_metadata (MediaItem item,
                                         string    uri,
                                         string[]  metadata) throws GLib.Error {
        if (metadata[Metadata.TITLE] != "")
            item.title = metadata[Metadata.TITLE];
        else
            /* If title wasn't provided, use filename instead */
            item.title = metadata[Metadata.FILE_NAME];

        if (metadata[Metadata.SIZE] != "")
            item.size = metadata[Metadata.SIZE].to_int64 ();
        else
            // If its in tracker store and size is unknown, it most probably
            // means the size is 0 (i-e a place-holder empty item that we
            // created).
            item.size = 0;

        if (metadata[Metadata.DATE] != "")
            item.date = metadata[Metadata.DATE];

        if (metadata[Metadata.DLNA_PROFILE] != "")
            item.dlna_profile = metadata[Metadata.DLNA_PROFILE];

        item.mime_type = metadata[Metadata.MIME];

        item.add_uri (uri);
    }
}

