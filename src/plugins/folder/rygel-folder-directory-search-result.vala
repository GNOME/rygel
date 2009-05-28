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

public class Rygel.FolderDirectorySearchResult : 
             Rygel.SimpleAsyncResult<Gee.List<MediaObject>> {
    private uint max_count;
    private uint offset;
    private File file;

    private const int MAX_CHILDREN = 10;

    public FolderDirectorySearchResult (MediaContainer     parent,
                                        uint               offset,
                                        uint               max_count,
                                        AsyncReadyCallback callback) {
        base (parent, callback);

        this.data = new ArrayList<MediaObject>();
        this.offset = offset;
        this.max_count = max_count;
    }

    public void enumerator_closed (Object obj, AsyncResult res) {
        var enumerator = (FileEnumerator) obj;

        try {
            enumerator.close_finish (res);
        } catch (Error e) {
            this.error = e;
        }

        this.complete();
    }

    public void enumerate_next_ready (Object obj, AsyncResult res) {
        var enumerator = (FileEnumerator) obj;
        try {
            var list = enumerator.next_files_finish (res);
            if (list != null) {
                foreach (FileInfo file_info in list) {
                    var f = file.get_child (file_info.get_name ());
                    MediaObject item = null;
                    if (file_info.get_file_type () == FileType.DIRECTORY) {
                        item = new Rygel.FolderContainer (
                                               (MediaContainer) source_object,
                                               f);

                    } else {
                        item = get_media_item ((MediaContainer) source_object,
                                               f,
                                               file_info);
                    }

                    if (item != null) {
                        data.add (item);
                    }
                }

                enumerator.next_files_async (MAX_CHILDREN,
                                             Priority.DEFAULT,
                                             null, enumerate_next_ready);
            } else {
                enumerator.close_async (Priority.DEFAULT,
                                        null, 
                                        enumerator_closed);
            }
        } catch (Error e) {
            this.error = e;
            this.complete ();
        }
    }

    public void enumerate_children_ready(Object obj, AsyncResult res) {
        file = (File) obj;

        try {
            var enumerator = file.enumerate_children_finish (res);

            enumerator.next_files_async (MAX_CHILDREN,
                                         Priority.DEFAULT,
                                         null, 
                                         enumerate_next_ready);
        } catch (Error error) {
            this.error = error;
            this.complete ();
        }
    }

    public Gee.List<MediaItem> get_children () {
        uint stop = offset + max_count;
        stop = stop.clamp (0, data.size);
        var children = data.slice ((int) offset, (int) stop);

        return children;
    }

    private MediaItem? get_media_item (MediaContainer parent,
                                       File           file,
                                       FileInfo       info) {
        string content_type = info.get_content_type ();
        string item_class = null;
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 info.get_name ());

        // use heuristics based on content type; will use MediaHarvester
        // when it's ready

        if (content_type.has_prefix ("video/")) {
            item_class = MediaItem.VIDEO_CLASS;
        } else if (content_type.has_prefix ("audio/")) {
            item_class = MediaItem.AUDIO_CLASS;
        } else if (content_type.has_prefix ("image/")) {
            item_class = MediaItem.IMAGE_CLASS;
        }

        if (null == item_class) {
            return null;
        }

        MediaItem item = new Rygel.MediaItem (id,
                                              parent,
                                              info.get_name (),
                                              item_class);
        item.mime_type = content_type;
        item.uris.add (GLib.Markup.escape_text (file.get_uri ()));

        return item;
    }
}

