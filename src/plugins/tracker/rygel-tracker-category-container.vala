/*
 * Copyright (C) 2010 Nokia Corporation.
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
 * Container listing content hierarchy for a specific category.
 */
public class Rygel.TrackerCategoryContainer : Rygel.SimpleContainer {
    public TrackerItemFactory item_factory;

    public TrackerCategoryContainer (string             id,
                                     MediaContainer     parent,
                                     string             title,
                                     TrackerItemFactory item_factory) {
        base (id, parent, title);

        this.item_factory = item_factory;

        this.add_child (new TrackerSearchContainer (this.id + "All",
                                                    this,
                                                    "All",
                                                    this.item_factory));

        try {
            var uri = Filename.to_uri (item_factory.upload_dir, null);
            this.uris.add (uri);
        } catch (ConvertError error) {
            warning ("Failed to contstruct URI for directory '%s': %s",
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

