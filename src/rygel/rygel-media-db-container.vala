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
        this.child_count = media_db.get_child_count (this.id);
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        var res = new SimpleAsyncResult<Gee.ArrayList<MediaObject>>
                                                            (this,
                                                             callback);
        res.data = this.media_db.get_children (this.id,
                                               offset,
                                               max_count);
        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                           AsyncResult res)
                                                           throws GLib.Error {
        var result = (SimpleAsyncResult<Gee.ArrayList<MediaObject>>)res;

        foreach (var obj in result.data) {
            obj.parent = this;
        }
        return result.data;
    }


    public override void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback) {
        var res = new SimpleAsyncResult<MediaObject> (this, callback);

        res.data = media_db.get_object (id);
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res) {
        return ((SimpleAsyncResult<MediaObject>)res).data;
    }
}


