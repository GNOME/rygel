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

public class Rygel.MediaDBContainer : MediaContainer {
    protected MediaDB media_db;

    public MediaDBContainer (MediaDB media_db, string id, string title) {
        int count;
        try {
            count = media_db.get_child_count (id);
        } catch (MediaDBError e) {
            debug("Could not get child count from database: %s",
                  e.message);
            count = 0;
        }
        base (id, null, title, count);

        this.media_db = media_db;
        this.container_updated.connect (on_db_container_updated);
    }

    private void on_db_container_updated (MediaContainer container,
                                          MediaContainer container_updated) {
        try {
            this.child_count = media_db.get_child_count (this.id);
        } catch (MediaDBError e) {
            debug("Could not get child count from database: %s",
                  e.message);
            this.child_count = 0;
        }
    }

    public override async Gee.List<MediaObject>? get_children (
                                        uint               offset,
                                        uint               max_count,
                                        Cancellable?       cancellable)
                                        throws GLib.Error {
        var children = this.media_db.get_children (this.id,
                                                   offset,
                                                   max_count);
        foreach (var child in children) {
            child.parent = this;
        }

        return children;
    }

    public override async MediaObject? find_object (string       id,
                                              Cancellable? cancellable)
                                              throws GLib.Error {
        return media_db.get_object (id);
    }
}


