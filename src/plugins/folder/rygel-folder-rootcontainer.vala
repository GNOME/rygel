/*
 * Copyright (C) 2008-2009 Jens Georg <mail@jensge.org>.
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
using GLib;
using Rygel;

/**
 * MediaContainer which exposes the contents of a directory 
 * as items
 */
public class Folder.FolderRootContainer : MediaContainer {
    private ArrayList<FolderContainer> items;

    public override void get_children(uint offset, 
                                      uint max_count,
                                      Cancellable? cancellable, 
                                      AsyncReadyCallback callback)
    {
        uint stop = offset + max_count;
        stop = stop.clamp(0, this.child_count);
        var children = this.items.slice ((int)offset, (int)stop);
        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>> (this, callback);
        res.data = children;
        res.complete_in_idle();
    }

    public override Gee.List<MediaObject>? get_children_finish (AsyncResult res) throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;
        return simple_res.data;
    }

    public override void find_object (string id, 
                                      Cancellable? cancellable,
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<string> (this, callback);

        res.data = id;
        res.complete_in_idle();
    }

    public override MediaObject? find_object_finish (AsyncResult res) throws GLib.Error {
        MediaObject item = null;
        var id = ((Rygel.SimpleAsyncResult<string>)res).data;

        foreach (MediaObject tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;
                break;
            }
        }

        return item;
    }

    /**
     * Create a new root container.
     * 
     * Schedules an async enumeration of the children of the 
     * directory
     * 
     * @parameter directory_path, directory you want to expose
     */
    public FolderRootContainer (string directory_path) {
        base.root(directory_path, 0);
        this.items = new ArrayList<FolderContainer> ();
        items.add(new FolderContainer(this, "12", directory_path, true));
        this.child_count = 1;
    }
}
