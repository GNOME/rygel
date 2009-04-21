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

    private const int MAX_CHILDREN = 10;

    /**
     * Flat storage of items found in directory
     */
    private ArrayList<MediaItem> items;

    /**
     * Instance of GLib.File of the directory we expose
     */
    private File root_dir;

    // methods overridden from MediaContainer

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
        MediaItem item = null;
        var id = ((Rygel.SimpleAsyncResult<string>)res).data;

        foreach (MediaItem tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;
                break;
            }
        }

        return item;
    }

    /**
     * Async callback for GLib.FileEnumerator.next_files_async
     * 
     * Will iterate over the list of FileInformation and 
     * create FilesystemMediaItems accordingly
     */
    private void on_enumerate_children_next_ready(Object obj, AsyncResult res) {
        GLib.FileEnumerator file_enumerator = (FileEnumerator)obj;

        try {
            var list = file_enumerator.next_files_finish(res);
            if (list != null) {
                foreach (FileInfo info in list) {
                    var file = this.root_dir.get_child(info.get_name());
                    var item = new FilesystemMediaItem(this, file, info);
                    if (item != null)
                        items.add(item);
                }
                file_enumerator.next_files_async (MAX_CHILDREN, 
                                                  Priority.DEFAULT, 
                                                  null, 
                                                  on_enumerate_children_next_ready);
            }
            else {
                file_enumerator.close(null);
                this.child_count = this.items.size;
                this.updated();
            }
        }
        catch (Error e) {
            warning("Failed to enumerate children: %s", e.message);
        }
    }

    /**
     * Async callback for GLib.File.enumerate_children_async
     *
     * Kick of async iteration over result
     */
    private void on_enumerate_children_ready(Object obj, AsyncResult res) {
        File file = (File)obj;

        try {
            var file_enumerator = file.enumerate_children_finish(res);
            file_enumerator.next_files_async (MAX_CHILDREN, 
                                              Priority.DEFAULT, 
                                              null, 
                                              on_enumerate_children_next_ready);
        }
        catch (Error e) {
            warning("Failed to enumerate children: %s", e.message);
        }
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
        this.items = new ArrayList<MediaItem> ();
        this.child_count = 0;

        this.root_dir = GLib.File.new_for_path(directory_path);

        root_dir.enumerate_children_async(FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE + "," +
                                          FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME + "," +
                                          FILE_ATTRIBUTE_STANDARD_NAME,
                                          FileQueryInfoFlags.NONE,
                                          Priority.DEFAULT, 
                                          null,
                                          on_enumerate_children_ready);
    }
}
