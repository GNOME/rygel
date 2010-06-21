/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2010 Nokia Corporation.
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

using Gee;

/**
 * A simple search container that contains all the items in a category.
 */
public class Rygel.TrackerCategoryAllContainer : Rygel.TrackerSearchContainer {
    public TrackerCategoryAllContainer (TrackerCategoryContainer parent) {
        base ("All" + parent.id, parent, "All", parent.item_factory);

        try {
            var uri = Filename.to_uri (item_factory.upload_dir, null);
            var create_classes = new ArrayList<string> ();

            create_classes.add (item_factory.upnp_class);
            this.set_uri (uri, create_classes);
        } catch (ConvertError error) {
            warning (_("Failed to construct URI for folder '%s': %s"),
                     item_factory.upload_dir,
                     error.message);
        }
    }

    public async override void add_item (MediaItem    item,
                                         Cancellable? cancellable)
                                         throws Error {
        assert (this.uris.size > 0);

        var creation = new TrackerItemCreation (item, this, cancellable);
        yield creation.run ();
        if (creation.error != null) {
            throw creation.error;
        }
    }
}

