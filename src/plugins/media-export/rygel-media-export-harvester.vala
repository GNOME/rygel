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

using GLib;
using Gee;

internal class Rygel.DummyContainer : Rygel.MediaContainer {
    public File file;
    public ArrayList<string> seen_children;

    public DummyContainer (File file, MediaContainer parent) {
        var id = Checksum.compute_for_string (ChecksumType.MD5,
                                              file.get_uri ());
        base (id, parent, file.get_basename (), 0);
        this.parent_ref = parent;
        this.file = file;
        this.uris.add (file.get_uri ());
        this.seen_children = new ArrayList<string> (str_equal);
    }

    public void seen (string id) {
        seen_children.add (id);
    }


    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {}

    public override Gee.List<MediaObject>? get_children_finish (
                                                    AsyncResult res)
                                                    throws Error
                                                    { return null; }

    public override void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback) { }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws Error { return
                                                     null;}

}

public class Rygel.MediaExportHarvester : GLib.Object {
    private MetadataExtractor extractor;
    private MediaDB media_db;
    private Queue<MediaContainer> containers;
    private Queue<File> files;
    private File origin;
    private MediaContainer parent;
    private MediaExportRecursiveFileMonitor monitor;

    public MediaExportHarvester (MediaContainer parent,
                                 MediaDB media_db,
                                 MetadataExtractor extractor,
                                 MediaExportRecursiveFileMonitor monitor) {
        this.parent = parent;
        this.extractor = extractor;
        this.media_db = media_db;
        this.extractor.extraction_done.connect (on_extracted_cb);
        this.extractor.error.connect (on_extractor_error_cb);
        this.files = new Queue<File> ();
        this.containers = new Queue<DummyContainer> ();
        this.origin = null;
        this.monitor = monitor;

        Idle.add (this.on_idle);
    }

    private void on_close_async (Object obj, AsyncResult res) {
        var enumerator = (FileEnumerator) obj;
        try {
            enumerator.close_finish (res);
        } catch (Error error) {
            // TODO
        }

        // delete all children which are not in filesystem anymore
        var container = (DummyContainer) this.containers.peek_head ();
        var children = this.media_db.get_child_ids (container.id);

        foreach (var seen_id in container.seen_children) {
            children.remove (seen_id);
        }

        foreach (var child in children) {
            this.media_db.delete_by_id (child);
        }

        if (this.files.get_length() == 0 &&
            this.containers.get_length () != 0) {
            this.containers.pop_head ();
        }

        Idle.add(this.on_idle);
    }

    private string push_if_changed_or_unknown (File file, FileInfo info) {
        var id = Checksum.compute_for_string (ChecksumType.MD5,
                                              file.get_uri ());
        int64 timestamp;
        if (media_db.exists (id, out timestamp)) {
            int64 mtime = (int64) info.get_attribute_uint64 (
                                                FILE_ATTRIBUTE_TIME_MODIFIED);

            if (mtime > timestamp) {
                this.files.push_tail (file);
            }
        } else {
            this.files.push_tail (file);
        }

        return id;
    }

    private void on_next_files_ready (Object obj, AsyncResult res) {
        var enumerator = (FileEnumerator) obj;
        try {
            var list = enumerator.next_files_finish (res);
            if (list != null) {
                foreach (var info in list) {
                    if (info.get_name ()[0] == '.') {
                        continue;
                    }
                    var parent_container =
                                 (DummyContainer)this.containers.peek_head ();

                    var dir = parent_container.file;
                    var file = dir.get_child (info.get_name ());
                    if (info.get_file_type () == FileType.DIRECTORY) {
                        monitor.monitor (file);
                        var container = new DummyContainer (file,
                                                            parent_container);
                        this.containers.push_tail (container);
                        parent_container.seen (container.id);
                        int64 timestamp;
                        if (!this.media_db.exists (container.id,
                                                   out timestamp)) {
                            this.media_db.save_object (container);
                        }
                    } else {
                        var id = push_if_changed_or_unknown (file, info);
                        parent_container.seen (id);
                    }
                }

                enumerator.next_files_async (10,
                                             Priority.DEFAULT,
                                             null,
                                             this.on_next_files_ready);
            } else {
                enumerator.close_async (Priority.DEFAULT,
                                        null,
                                        this.on_close_async);
            }
        } catch (Error error) {
            // TODO
        }
    }

    private void on_enumerate_ready (Object obj, AsyncResult res) {
        var file = (File) obj;
        try {
            var enumerator = file.enumerate_children_finish (res);
            enumerator.next_files_async (10,
                                         Priority.DEFAULT,
                                         null,
                                         on_next_files_ready);
        } catch (Error error) {
            // TODO
        }
    }

    private bool on_idle () {
        if (this.files.get_length () > 0) {
            var candidate = this.files.peek_head ();
            this.extractor.extract (candidate);
        } else if (this.containers.get_length () > 0) {
            var directory = ((DummyContainer)this.containers.peek_head ()).file;
            directory.enumerate_children_async (
                            FILE_ATTRIBUTE_STANDARD_TYPE + "," +
                            FILE_ATTRIBUTE_STANDARD_NAME + "," +
                            FILE_ATTRIBUTE_TIME_MODIFIED,
                            FileQueryInfoFlags.NONE,
                            Priority.DEFAULT,
                            null,
                            this.on_enumerate_ready);
        } else {
            // nothing to do
            harvested (this.origin);
            this.origin = null;
        }

        return false;
    }

    /**
     * Fired for every file passed to harvest.
     */
    public signal void harvested (File file);

    /**
     * Extract all metainformation from a given file.
     *
     * What action will be taken depends on the arguments
     * * file is a simple file. Then only information of this
     *   file will be extracted
     * * file is a directory and recursive is false. The children
     *   of the directory (if not directories themselves) will be
     *   enqueued for extraction
     * * file is a directory and recursive is true. ++ All ++ children
     *   of the directory will be enqueued for extraction, even directories
     *
     * No matter how many children are contained within file's hierarchy,
     * only one event is sent when all the children are done.
     */
    public void harvest (File file) {
        if (file.query_exists (null)) {
            try {
                var info = file.query_info (
                             FILE_ATTRIBUTE_STANDARD_NAME + "," +
                             FILE_ATTRIBUTE_STANDARD_TYPE,
                             FileQueryInfoFlags.NONE,
                             null);
                if (info.get_file_type () == FileType.DIRECTORY) {
                    this.origin = file;
                    monitor.monitor (file);
                    this.containers.push_tail (
                                new DummyContainer (file,
                                                          this.parent));

                    this.media_db.save_object (this.containers.peek_tail ());
                } else {
                    this.origin = file;
                    this.files.push_tail (file);
                    this.containers.push_tail (this.parent);
                }
            } catch (Error error) {
                debug ("Failed to query info for file %s: %s",
                       file.get_uri (),
                       error.message);
            }
        }
    }

    private void on_extracted_cb (File file, Gst.TagList tag_list) {
        if (file == this.files.peek_head ()) {
            var item = MediaExportItem.create_from_taglist (
                                               this.containers.peek_head (),
                                               file,
                                               tag_list);
            item.parent_ref = this.containers.peek_head ();
            try {
                this.media_db.save_object (item);
            } catch (Error error) {
                // Ignore it for now
            }

            this.files.pop_head ();
            if (this.files.get_length () == 0 &&
                this.containers.get_length () != 0) {
                this.containers.peek_head ().updated ();
                this.containers.pop_head ();
            }
            Idle.add(this.on_idle);
        }
    }

    private void on_extractor_error_cb (File file, Error error) {
        if (file == this.files.peek_head ()) {
            debug ("failed to harvest file %s", file.get_uri ());
            // yadda yadda
            this.files.pop_head ();
            if (this.files.get_length () == 0 &&
                this.containers.get_length () != 0) {
                this.containers.peek_head ().updated ();
                this.containers.pop_head ();
            }
            Idle.add(this.on_idle);
        }
    }
}
