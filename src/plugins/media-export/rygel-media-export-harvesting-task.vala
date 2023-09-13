/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GLib;
using Gee;
using Gst.PbUtils;

internal class FileQueueEntry {
    public File file;
    public bool known;
    public string content_type;

    public FileQueueEntry (File file, bool known, string content_type) {
        this.file = file;
        this.known = known;
        this.content_type = content_type;
    }
}

public class Rygel.MediaExport.HarvestingTask : Rygel.StateMachine,
                                                GLib.Object {
    public File origin;
    private Timer timer;
    private MetadataExtractor extractor;
    private MediaCache cache;
    private GLib.Queue<MediaContainer> containers;
    private Gee.Queue<FileQueueEntry> files;
    private RecursiveFileMonitor monitor;
    private MediaContainer parent;
    private const int BATCH_SIZE = 256;

    public Cancellable cancellable { get; set; }

    private const string HARVESTER_ATTRIBUTES =
                                        FileAttribute.STANDARD_NAME + "," +
                                        FileAttribute.STANDARD_TYPE + "," +
                                        FileAttribute.STANDARD_SIZE + "," +
                                        FileAttribute.TIME_MODIFIED + "," +
                                        FileAttribute.STANDARD_IS_HIDDEN;

    private const string HARVESTER_MIME_TYPE_ATTRIBUTES =
                                        FileAttribute.STANDARD_CONTENT_TYPE;

    public HarvestingTask (RecursiveFileMonitor monitor,
                           File                 file,
                           MediaContainer       parent) {
        this.extractor = new MetadataExtractor ();
        this.origin = file;
        this.parent = parent;
        this.cache = MediaCache.get_default ();

        this.extractor.extraction_done.connect (this.on_extracted_cb);
        this.extractor.error.connect (this.on_extractor_error_cb);

        this.files = new LinkedList<FileQueueEntry> ();
        this.containers = new GLib.Queue<MediaContainer> ();
        this.monitor = monitor;
        this.timer = new Timer ();
    }

    ~HarvestingTask () {
        this.extractor.stop ();
    }

    public void cancel () {
        // detach from common cancellable; otherwise everything would be
        // cancelled like file monitoring, other harvesters etc.
        this.cancellable = new Cancellable ();
        this.cancellable.cancel ();
        this.extractor.stop ();
    }

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
    public async void run () {
        this.timer.reset ();
        try {
            this.extractor.run.begin ();

            var info = yield this.origin.query_info_async
                                        (HARVESTER_ATTRIBUTES,
                                         FileQueryInfoFlags.NONE,
                                         Priority.DEFAULT,
                                         this.cancellable);

            if (this.process_file (this.origin, info, this.parent)) {
                if (info.get_file_type () != FileType.DIRECTORY) {
                    this.containers.push_tail (this.parent);
                }
                this.on_idle ();
            } else {
                this.completed ();
            }
        } catch (Error error) {
            this.extractor.stop ();
            if (!(error is IOError.CANCELLED)) {
                warning (_("Failed to harvest file %s: %s"),
                         this.origin.get_uri (),
                         error.message);
            } else {
                debug ("Harvesting of uri %s was cancelled",
                       this.origin.get_uri ());
            }
            this.completed ();
        }
    }

    /**
     * Add a file to the meta-data extraction queue.
     *
     * The file will only be added to the queue if one of the following
     * conditions is met:
     *   - The file is not in the cache
     *   - The current mtime of the file is larger than the cached
     *   - The size has changed
     * @param file to check
     * @param info FileInfo of the file to check, containing at
     *             least size, mtime and type (but not necessarily
     *             mime type)
     * @return true, if the file has been queued, false otherwise.
     */
    private bool push_if_changed_or_unknown (File       file,
                                             FileInfo   info) {
        try {
            int64 timestamp;
            int64 size;
            string mime_type;

            bool is_cached = this.cache.exists (file, out timestamp, out size, out mime_type);
            if (is_cached) {
                int64 mtime = (int64) info.get_attribute_uint64
                                        (FileAttribute.TIME_MODIFIED);
                if (mtime <= timestamp &&
                    info.get_size () == size) {
                    return false;
                }

                info.set_content_type(mime_type);
            }

            if (!info.has_attribute (FileAttribute.STANDARD_CONTENT_TYPE) || info.get_content_type () == null) {
                var extended_info = file.query_info
                                        (HARVESTER_MIME_TYPE_ATTRIBUTES,
                                         FileQueryInfoFlags.NONE);
                info.set_content_type (extended_info.get_content_type ());
            }

            // Check if the file needs to be harvested at all either because
            // it is denied by filter or it hasn't updated
            if (!Harvester.is_eligible (file, info)) {
                return false;
            }

            var entry = new FileQueueEntry (file,
                                            is_cached,
                                            info.get_content_type ());
            this.files.offer (entry);

            return true;
        } catch (Error error) {
            warning (_("Failed to query database: %s"), error.message);
        }

        return false;
    }

    private bool process_file (File           file,
                               FileInfo       info,
                               MediaContainer parent) {
        if (info.get_is_hidden ()) {
            return false;
        }

        if (info.get_file_type () == FileType.DIRECTORY) {
            // Check if we have an "exploded" DVD structure
            if (file.get_child ("VIDEO_TS").query_exists ()) {
                info.set_file_type (FileType.REGULAR);
                info.set_content_type ("application/x-cd-image");
            }
        }

        if (info.get_file_type () == FileType.DIRECTORY) {
            if (!Harvester.is_eligible (file, info)) {
                return false;
            }

            // queue directory for processing later
            this.monitor.add.begin (file);

            var container = new DummyContainer (file, parent);
            this.containers.push_tail (container);

            // Only add new containers. There's not much about a container so
            // we skip the updated signal
            var dummy_parent = parent as DummyContainer;
            if (dummy_parent == null ||
                !dummy_parent.children.contains (MediaCache.get_id (file))) {
                ((TrackableContainer) parent).add_child_tracked.begin (container);
            }

            return true;
        } else {
            return this.push_if_changed_or_unknown (file, info);
        }
    }

    private bool process_children (GLib.List<FileInfo>? list) {
        if (list == null || this.cancellable.is_cancelled ()) {
            return false;
        }

        var container = this.containers.peek_head () as DummyContainer;

        foreach (var info in list) {
            var file = container.file.get_child (info.get_name ());

            this.process_file (file, info, container);
            container.seen (file);
        }

        return true;
    }

    private async void enumerate_directory () {
        var directory = ((DummyContainer) this.containers.peek_head ()).file;
        try {
            var enumerator = yield directory.enumerate_children_async
                                        (HARVESTER_ATTRIBUTES,
                                         FileQueryInfoFlags.NONE,
                                         Priority.DEFAULT,
                                         this.cancellable);

            GLib.List<FileInfo> list = null;
            do {
                list = yield enumerator.next_files_async (BATCH_SIZE,
                                                          Priority.DEFAULT,
                                                          this.cancellable);
            } while (this.process_children (list));

            yield enumerator.close_async (Priority.DEFAULT, this.cancellable);
        } catch (Error err) {
            warning (_("Failed to enumerate folder “%s”: %s"),
                     directory.get_path (),
                     err.message);
        }

        this.cleanup_database ();
        this.do_update ();
    }

    private void cleanup_database () {
        var container = this.containers.peek_head () as DummyContainer;

        // delete all children which are not in filesystem anymore
        try {
            foreach (var child in container.children) {
                this.cache.remove_by_id (child);
            }
        } catch (Database.DatabaseError error) {
            warning (_("Failed to get children of container %s: %s"),
                     container.id,
                     error.message);
        }
    }

    private bool on_idle () {
        if (this.cancellable.is_cancelled ()) {
            this.completed ();

            return false;
        }

        if (!this.files.is_empty) {
            debug ("Scheduling file %s for meta-data extraction…",
                   this.files.peek ().file.get_uri ());
            this.extractor.extract (this.files.peek ().file,
                                    this.files.peek ().content_type);
        } else if (!this.containers.is_empty ()) {
            this.enumerate_directory.begin ();
        } else {
            // nothing to do
            this.completed ();
            message ("Harvesting of %s done in %f",
                    origin.get_uri (),
                    timer.elapsed ());
        }

        return false;
    }

    private void on_extracted_cb (File               file,
                                  Variant?           info) {
        if (!file.equal (this.files.peek ().file)) {
            debug ("Not for us, ignoring");
        }

        if (this.cancellable.is_cancelled ()) {
            this.completed ();
        }

        try {
            var parent = this.containers.peek_head ();
            var item = ItemFactory.create_from_variant (parent,
                                                        file,
                                                        info);

            if (item != null) {
                item.parent_ref = parent;
                // This is only necessary to generate the proper <objAdd LastChange
                // entry
                if (this.files.peek ().known) {
                    ((UpdatableObject) item).non_overriding_commit.begin ();
                } else {
                    var container = (TrackableContainer) item.parent;
                    container.add_child_tracked.begin (item) ;
                }
            }
        } catch (Error error) {
            warning (_("Failed to extract meta-data for file %s"),
                     error.message);
        }

        this.files.poll ();
        this.do_update ();
    }

    private void on_extractor_error_cb (File file, Error error) {
        // error is only emitted if even the basic information extraction
        // failed; there's not much to do here, just print the information and
        // go to the next file

        warning (_("Skipping URI %s; extraction completely failed: %s"),
               file.get_uri (),
               error.message);

        this.cache.ignore (file);

        this.files.poll ();
        this.do_update ();
    }

    /**
     * If all files of a container were processed, notify the container
     * about this and set the updating signal.
     * Reschedule the iteration and extraction
     */
    private void do_update () {
        if (this.files.is_empty &&
            !this.containers.is_empty ()) {
            this.containers.pop_head ();
        }

        this.on_idle ();
    }
}
