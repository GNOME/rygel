/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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
using Tracker;

/**
 * Tracker picture item factory.
 */
public class Rygel.Tracker.PictureItemFactory : ItemFactory {
    private enum PictureMetadata {
        HEIGHT = Metadata.LAST_KEY,
        WIDTH,

        LAST_KEY
    }

    private const string CATEGORY = "nmm:Photo";
    private const string CATEGORY_IRI = "http://www.tracker-project.org/" +
                                        "temp/nmm#Photo";

    public PictureItemFactory () {
        var upload_folder = Environment.get_user_special_dir
                                        (UserDirectory.PICTURES);
        try {
            var config = MetaConfig.get_default ();
            upload_folder = config.get_picture_upload_folder ();
        } catch (Error error) {};

        base (CATEGORY, CATEGORY_IRI, PhotoItem.UPNP_CLASS, upload_folder);

        // These must be in the same order as enum PictureMetadata
        this.properties.add ("height");
        this.properties.add ("width");
    }

    public override MediaFileItem create (string          id,
                                          string          uri,
                                          SearchContainer parent,
                                          Sparql.Cursor   metadata)
                                          throws GLib.Error {
        var item = new PhotoItem (id, parent, "");

        this.set_metadata (item, uri, metadata);

        return item;
    }

    protected override void set_metadata (MediaFileItem item,
                                          string        uri,
                                          Sparql.Cursor metadata)
                                          throws GLib.Error {
        base.set_metadata (item, uri, metadata);

        this.set_ref_id (item, "AllPictures");

        var photo = item as PhotoItem;

        if (metadata.is_bound (PictureMetadata.WIDTH)) {
            photo.width = (int) metadata.get_integer (PictureMetadata.WIDTH);
        }

        if (metadata.is_bound (PictureMetadata.HEIGHT)) {
            photo.height = (int) metadata.get_integer (PictureMetadata.HEIGHT);
        }
    }
}

