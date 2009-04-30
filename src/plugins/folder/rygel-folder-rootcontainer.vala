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

public class Folder.DirectorySearchResult : Rygel.SimpleAsyncResult<Gee.List<MediaItem>> {
    private uint max_count;
    private uint offset;

    public DirectorySearchResult(MediaContainer parent, uint offset, uint max_count, AsyncReadyCallback callback) {
        base(parent, callback);

        this.data = new ArrayList<MediaItem>();
        this.offset = offset;
        this.max_count = max_count;
    }

    public void enumerate_children_ready(Object obj, AsyncResult res) {
        File file = (File)obj;
        try {
            var enumerator = file.enumerate_children_finish(res);
            var file_info = enumerator.next_file(null);
            while (file_info != null) {
                var f = file.get_child(file_info.get_name());
                try {
                    var item = new FilesystemMediaItem((MediaContainer)source_object, f, file_info);
                    if (item != null)
                    data.add(item);
                } catch (MediaItemError err) {
                    // most likely invalid content type
                }
                file_info = enumerator.next_file(null);
            }

            this.complete();
        }
        catch (Error error) {
            this.error = error;
            this.complete();
        }
    }

    public Gee.List<MediaItem> get_children() {
        uint stop = offset + max_count;
        stop = stop.clamp(0, data.size);
        var children = data.slice ((int)offset, (int)stop);

        return children;
    }
}

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

    private Gee.List<AsyncResult> results;

    // methods overridden from MediaContainer

    public override void get_children(uint offset, 
                                      uint max_count,
                                      Cancellable? cancellable, 
                                      AsyncReadyCallback callback)
    {
        if (items.size == 0) {
            DirectorySearchResult res = new DirectorySearchResult(this, offset, max_count, callback);
            root_dir.enumerate_children_async(FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE + "," +
                                              FILE_ATTRIBUTE_STANDARD_DISPLAY_NAME + "," +
                                              FILE_ATTRIBUTE_STANDARD_NAME,
                                              FileQueryInfoFlags.NONE,
                                              Priority.DEFAULT, 
                                              null,
                                              res.enumerate_children_ready);
            this.results.add(res);
        }
        else {
            uint stop = offset + max_count;
            stop = stop.clamp(0, this.child_count);
            var children = this.items.slice ((int)offset, (int)stop);
            var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>> (this, callback);
            res.data = children;
            res.complete_in_idle();
        }
    }

    public override Gee.List<MediaObject>? get_children_finish (AsyncResult res) throws GLib.Error {
        if (res is DirectorySearchResult) {
            var dsr = (DirectorySearchResult)res;
            foreach (var item in dsr.data) {
                this.items.add(item);
            }
            this.child_count = this.items.size;
            this.results.remove(res);
            return dsr.get_children();
        }
        else {
            var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;
            return simple_res.data;
        }
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
                    try {
                        var item = new FilesystemMediaItem(this, file, info);
                        items.add(item);
                    } catch (MediaItemError err) {
                        // most likely invalid content type
                    }
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
        this.results = new ArrayList<AsyncResult>();

        this.root_dir = GLib.File.new_for_path(directory_path);
    }
}
