/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
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
using GConf;

/**
 * MediaContainer which exposes the contents of a directory 
 * as items
 */
public class Rygel.FolderRootContainer : MediaContainer {
    private ArrayList<FolderContainer> items;

    public override void get_children (uint offset, 
                                       uint max_count,
                                       Cancellable? cancellable, 
                                       AsyncReadyCallback callback)
    {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);
        var children = this.items.slice ((int) offset, (int) stop);
        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>> (this, 
                                                                      callback);
        res.data = children;
        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                    AsyncResult res) 
                                                    throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;

        return simple_res.data;
    }

    public override void find_object (string id, 
                                      Cancellable? cancellable,
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<string> (this, callback);

        res.data = id;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res) 
                                                     throws GLib.Error {
        MediaObject item = null;
        var id = ((Rygel.SimpleAsyncResult<string>) res).data;

        foreach (var tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;
                break;
            }
        }

        if (item == null) {
            foreach (var tmp in items) {
                if (tmp is FolderContainer) {
                    var folder = (FolderContainer) tmp;
                    item = folder.find_object_sync (id);
                    if (item != null) {
                        break;
                    }
                }
            }
        }

        return item;
    }

    /**
     * Create a new root container.
     */
    public FolderRootContainer () {
        base.root ("FolderRoot", 0);

        this.items = new ArrayList<FolderContainer> ();

        var config = Rygel.Configuration.get_default ();
        var dirs = config.get_string_list ("Folder", "folders");

        // either an error occured or the gconf key is not set
        if (dirs.size == 0) {
            var dir = Environment.get_user_special_dir (UserDirectory.MUSIC);
            if (dir != null)
                dirs.add (dir);

            dir = Environment.get_user_special_dir (UserDirectory.PICTURES);
            if (dir != null)
                dirs.add (dir);

            dir = Environment.get_user_special_dir (UserDirectory.VIDEOS);
            if (dir != null)
                dirs.add (dir);
        }

        foreach (var dir in dirs) {
            var f = File.new_for_commandline_arg (dir);
            if (f.query_exists (null)) {
                items.add (new FolderContainer (this, f));
            }
        }

        this.child_count = items.size;
    }
}
