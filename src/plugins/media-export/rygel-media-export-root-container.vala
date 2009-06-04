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
 * Represents the root container.
 */
public class Rygel.MediaExportRootContainer : MediaContainer {
    private ArrayList<MediaExportContainer> children;

    public override void get_children (uint offset,
                                       uint max_count,
                                       Cancellable? cancellable,
                                       AsyncReadyCallback callback)
    {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);
        var children = this.children.slice ((int) offset, (int) stop);
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

        foreach (var tmp in this.children) {
            if (id == tmp.id) {
                item = tmp;
                break;
            }
        }

        if (item == null) {
            foreach (var tmp in this.children) {
                if (tmp is MediaExportContainer) {
                    var folder = (MediaExportContainer) tmp;
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
    public MediaExportRootContainer () {
        base.root ("MediaExportRoot", 0);

        this.children = new ArrayList<MediaExportContainer> ();

        var config = Rygel.Configuration.get_default ();
        var uris = config.get_string_list ("MediaExport", "folders");

        // either an error occured or the gconf key is not set
        if (uris.size == 0) {
            var uri = Environment.get_user_special_dir (UserDirectory.MUSIC);
            if (uri != null)
                uris.add (uri);

            uri = Environment.get_user_special_dir (UserDirectory.PICTURES);
            if (uri != null)
                uris.add (uri);

            uri = Environment.get_user_special_dir (UserDirectory.VIDEOS);
            if (uri != null)
                uris.add (uri);
        }

        foreach (var uri in uris) {
            var f = File.new_for_commandline_arg (uri);
            if (f.query_exists (null)) {
                this.children.add (new MediaExportContainer (this, f));
            }
        }

        this.child_count = this.children.size;
    }
}
