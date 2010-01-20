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

using Gee;

/**
 * Container listing Pictures content hierarchy.
 */
public class Rygel.TrackerPictures : Rygel.SimpleContainer {
    private const string[] KEY_CHAIN = { "nie:contentCreated", null };

    public TrackerPictures (string         id,
                            MediaContainer parent,
                            string         title) {
        base (id, parent, title);

        var item_factory = new TrackerPictureItemFactory ();

        this.add_child (new TrackerTags ("19", this, item_factory));
        this.add_child (new TrackerYears ("22", this, item_factory));
        this.add_child (new TrackerSearchContainer ("25",
                                                    this,
                                                    "All",
                                                    item_factory));
        try {
            var dir = Environment.get_user_special_dir (UserDirectory.PICTURES);
            var uri = Filename.to_uri (dir, null);

            this.uris.add (uri);
        } catch (ConvertError error) {
            warning ("Failed to get URI for pictures directory: %s",
                     error.message);
        }
    }
}

