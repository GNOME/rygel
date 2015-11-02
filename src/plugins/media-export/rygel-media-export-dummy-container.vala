/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
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
using Gee;

internal class Rygel.MediaExport.DummyContainer : TrackableDbContainer {
    public File file;
    public Gee.List<string> children;

    public DummyContainer (File           file,
                           MediaContainer parent) {
        var cache = MediaCache.get_default ();

        base (MediaCache.get_id (file), file.get_basename ());

        uint32 object_update_id, container_update_id, total_deleted_child_count;
        this.media_db.get_track_properties (this.id,
                                            out object_update_id,
                                            out container_update_id,
                                            out total_deleted_child_count);
        this.object_update_id = object_update_id;
        this.update_id = container_update_id;
        this.total_deleted_child_count = total_deleted_child_count;

        this.parent_ref = parent;
        this.file = file;
        this.add_uri (file.get_uri ());
        try {
            this.children = cache.get_child_ids (this.id);
            this.child_count = this.children.size;
        } catch (Error error) {
            this.children = new ArrayList<string> ();
            this.child_count = 0;
        }
    }

    public void seen (File file) {
        this.children.remove (MediaCache.get_id (file));
    }
}
