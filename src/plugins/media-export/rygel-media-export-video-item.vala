/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

internal class Rygel.MediaExport.VideoItem : Rygel.VideoItem,
                                             Rygel.UpdatableObject,
                                             Rygel.MediaExport.UpdatableObject,
                                             Rygel.TrackableItem {
    public VideoItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = Rygel.VideoItem.UPNP_CLASS) {
        base (id, parent, title, upnp_class);
    }

    public async void commit () throws Error {
        yield this.commit_custom (true);
    }

    public virtual async void commit_custom (bool override_guarded) throws Error {
        this.changed ();
        var cache = MediaCache.get_default ();
        cache.save_item (this, override_guarded);
    }

}
