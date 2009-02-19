/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using Rygel;

/**
 * Handles Tracker Metadata.Get method results.
 *
 */
public class Rygel.TrackerGetMetadataResult :
             Rygel.SimpleAsyncResult<MediaObject> {
    protected string item_id;

    public TrackerGetMetadataResult (TrackerCategory    category,
                                     AsyncReadyCallback callback,
                                     string             item_id) {
        base (category, callback);
        this.item_id = item_id;
    }

    public void ready (string[] metadata, Error error) {
        if (error != null) {
            this.error = error;

            this.complete ();
            return;
        }

        TrackerCategory category = (TrackerCategory) this.source_object;

        string path = category.get_item_path (item_id);
        this.data = category.create_item (path, metadata);

        this.complete ();
    }
}
