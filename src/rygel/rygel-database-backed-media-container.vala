/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Rygel;

public class Rygel.DatabaseBackedMediaContainer : Rygel.MediaContainer {
    private MediaDB media_db;

    public DatabaseBackedMediaContainer (Rygel.MediaDB media_db,
                                         string id,
                                         string title) {
        base (id, null, title, 0);

        this.media_db = media_db;
    }

    public override void get_children (uint offset,
                                       uint max_count,
                                       Cancellable? cancellable,
                                       AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<Gee.ArrayList<MediaObject>>
                                                            (this, callback);
        res.data = this.media_db.get_children (this.id,
                                               offset,
                                               max_count);
        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                           AsyncResult res)
                                                           throws GLib.Error {
        return ((Rygel.SimpleAsyncResult<Gee.ArrayList<MediaObject>>)res).data;
    }


    public override void find_object (string id,
                                      Cancellable? cancellable,
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        res.data = media_db.get_object (id);
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res) {
        return ((Rygel.SimpleAsyncResult<MediaObject>)res).data;
    }
}


