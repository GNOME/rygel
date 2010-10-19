/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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
using GUPnP;

public class Rygel.MediaExport.DBContainer : MediaContainer {
    protected MediaCache media_db;

    public DBContainer (MediaCache media_db, string id, string title) {
        base (id, null, title, 0);

        this.media_db = media_db;
        this.container_updated.connect (on_db_container_updated);
        this.on_db_container_updated (this, this);
    }

    private void on_db_container_updated (MediaContainer container,
                                          MediaContainer container_updated) {
        try {
            this.child_count = this.media_db.get_child_count (this.id);
        } catch (DatabaseError error) {
            debug ("Could not get child count from database: %s",
                   error.message);
            this.child_count = 0;
        }
    }

    public override async MediaObjects? get_children (uint         offset,
                                                      uint         max_count,
                                                      Cancellable? cancellable)
                                                      throws GLib.Error {
        return this.media_db.get_children (this, offset, max_count);
    }

    public override async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                out uint          total_matches,
                                                Cancellable?      cancellable)
                                                throws GLib.Error {
        MediaObjects children = null;

        try {
            children = this.media_db.get_objects_by_search_expression (
                                        expression,
                                        this.id,
                                        offset,
                                        max_count,
                                        out total_matches);
        } catch (MediaCacheError error) {
            if (error is MediaCacheError.UNSUPPORTED_SEARCH) {
                children = yield base.search (expression,
                                              offset,
                                              max_count,
                                              out total_matches,
                                              cancellable);
            } else {
                throw error;
            }
        }

        return children;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        return this.media_db.get_object (id);
    }

    public override async void add_item (Rygel.MediaItem item,
                                         Cancellable?    cancellable)
                                         throws Error {
        item.parent = this;
        item.id = MediaCache.get_id (File.new_for_uri (item.uris[0]));
        this.media_db.save_item (item);
    }

}
