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
public abstract class Rygel.TrackerItemFactory {
    protected enum Metadata {
        FILE_NAME,
        TITLE,
        MIME,
        SIZE,
        DATE,

        LAST_KEY
    }

    public string category;
    public string upnp_class;

    public TrackerItemFactory (string category,
                               string upnp_class) {
        this.category = category;
        this.upnp_class = upnp_class;
    }

    public virtual MediaItem create (string                 id,
                                     string                 uri,
                                     TrackerSearchContainer parent,
                                     string[]               metadata)
                                     throws GLib.Error {
        var item = new MediaItem (id, parent, "", this.upnp_class);

        if (metadata[Metadata.TITLE] != "")
            item.title = metadata[Metadata.TITLE];
        else
            /* If title wasn't provided, use filename instead */
            item.title = metadata[Metadata.FILE_NAME];

        if (metadata[Metadata.SIZE] != "")
            item.size = metadata[Metadata.SIZE].to_int ();

        if (metadata[Metadata.DATE] != "")
            item.date = metadata[Metadata.DATE];

        item.mime_type = metadata[Metadata.MIME];

        item.add_uri (uri, null);

        return item;
    }

    public virtual ArrayList<string> get_metadata_keys () {
        var keys = new ArrayList<string> ();
        keys.add ("nfo:fileName");        // Metadata.FILE_NAME
        keys.add ("nie:title");           // Metadata.TITLE
        keys.add ("nie:mimeType");        // Metadata.MIME
        keys.add ("nfo:fileSize");        // Metadata.SIZE
        keys.add ("nie:contentCreated");  // Metadata.DATE

        assert (keys.size == Metadata.LAST_KEY);

        return keys;
    }
}

