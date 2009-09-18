/*
 * Copyright (C) 2009 Nokia Corporation.
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

/**
 * Handles Tracker Metadata.Get method results.
 *
 */
public class Rygel.TrackerGetMetadataResult :
             Rygel.SimpleAsyncResult<MediaObject> {
    protected string item_id;
    protected string item_path;
    protected string item_service;

    public TrackerGetMetadataResult (TrackerSearchContainer search_container,
                                     AsyncReadyCallback     callback,
                                     string                 item_id) {
        base (search_container, callback);
        this.item_id = item_id;
    }

    public void ready (string[] metadata, Error error) {
        if (error != null) {
            this.error = error;

            this.complete ();
            return;
        }

        var search_container = (TrackerSearchContainer) this.source_object;

        this.data = search_container.create_item (this.item_service,
                                                  this.item_path,
                                                  metadata);

        this.complete ();
    }
}
