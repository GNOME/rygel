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
using Rygel;
using GLib;

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


