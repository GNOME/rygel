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

/**
 * MediaContainer which exposes the contents of a directory.
 *
 * The folder contents will be queried on demand and cached afterwards
 */
public class Rygel.MediaExportContainer : MediaContainer {

    /**
     * Number of children to use for crawling the subdir
     */
    private const int MAX_CHILDREN = 10;

    /**
     * Cache of children found in directory
     */
    private ArrayList<MediaObject> children;

    /**
     * Instance of GLib.File of the directory we expose
     */
    private File root_dir;

    private Gee.List<AsyncResult> results;

    // methods overridden from MediaContainer
    public override void get_children (uint offset,
                                       uint max_count,
                                       Cancellable? cancellable,
                                       AsyncReadyCallback callback) {
        // if the cache is empty, fill it
        if (this.children.size == 0) {
            var res = new MediaExportDirectorySearchResult (this,
                                                            offset,
                                                            max_count,
                                                            callback);

            root_dir.enumerate_children_async (
                                FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE + "," +
                                FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME + "," +
                                FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                                FILE_ATTRIBUTE_STANDARD_NAME,
                                FileQueryInfoFlags.NONE,
                                Priority.DEFAULT,
                                null,
                                res.enumerate_children_ready);
            this.results.add (res);
        } else {
            uint stop = offset + max_count;
            stop = stop.clamp (0, this.child_count);
            var children = this.children.slice ((int) offset, (int) stop);
            var res =
                new SimpleAsyncResult<Gee.List<MediaObject>> (
                            this,
                            callback);
            res.data = children;
            res.complete_in_idle ();
        }
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                         AsyncResult res)
                                                         throws GLib.Error {
        if (res is MediaExportDirectorySearchResult) {
            var dsr = (MediaExportDirectorySearchResult) res;

            foreach (var media_obj in dsr.data) {
                this.children.add (media_obj);
            }

            this.child_count = this.children.size;
            this.results.remove (res);
            return dsr.get_children ();
        } else {
            var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>)
                            res;
            return simple_res.data;
        }
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
        var id = ((Rygel.SimpleAsyncResult<string>) res).data;

        return find_object_sync (id);
    }

    public MediaObject? find_object_sync (string id) {
        MediaObject media_obj = null;

        // check if the searched object is in our cache
        foreach (var tmp in this.children) {
            if (id == tmp.id) {
                media_obj = tmp;
                break;
            }
        }

        // if not found, do a depth-first search on the child
        // folders
        if (media_obj == null) {
            foreach (var tmp in this.children) {
                if (tmp is MediaExportContainer) {
                    var folder = (MediaExportContainer) tmp;
                    media_obj = folder.find_object_sync (id);
                    if (media_obj != null) {
                        break;
                    }
                }
            }
        }

        return media_obj;
    }

    /**
     * Create a new container.
     *
     * @parameter parent, parent container
     * @parameter file, directory you want to expose
     */
    public MediaExportContainer (MediaContainer parent, File file) {
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 file.get_uri ());

        base(id, parent, file.get_basename (), 0);
        this.root_dir = file;

        this.children = new ArrayList<MediaObject> ();
        this.child_count = 0;
        this.results = new ArrayList<AsyncResult> ();
    }
}
