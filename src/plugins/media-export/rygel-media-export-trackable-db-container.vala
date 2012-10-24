/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

public class Rygel.MediaExport.TrackableDBContainer : DBContainer,
                                                        Rygel.TrackableContainer {
    public TrackableDBContainer (MediaCache media_db,
                                 string id,
                                 string title) {
        base (media_db, id, title);
    }

    public async void add_child (MediaObject object) {
        try {
            if (object is MediaContainer) {
                this.media_db.save_container (object as MediaContainer);
            } else {
                this.media_db.save_item (object as MediaItem);
            }
        } catch (Error error) { }
    }

    public async void remove_child (MediaObject object) {
        try {
            this.media_db.remove_by_id (object.id);
        } catch (Error error) { }
    }
}
