/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
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

/**
 * This class takes care of the book-keeping of running and finished
 * extraction tasks running within the media-export plugin
 */
internal class Rygel.MediaExport.Harvester : GLib.Object {
    private HashMap<File, HarvestingTask> tasks;
    private MetadataExtractor extractor;
    private RecursiveFileMonitor monitor;
    private Regex file_filter;
    private Cancellable cancellable;

    /**
     * Create a new instance of the meta-data extraction manager.
     */
    public Harvester (Cancellable cancellable) {
        this.cancellable = cancellable;
        this.extractor = new MetadataExtractor ();

        this.monitor = new RecursiveFileMonitor (cancellable);
        this.monitor.changed.connect (this.on_file_changed);

        this.tasks = new HashMap<File, HarvestingTask> (file_hash, file_equal);
        this.create_file_filter ();
    }

    /**
     * Put a file on queue for meta-data extraction
     *
     * @param file the file to investigate
     * @param parent container of the filer to be harvested
     * @param flag optional flag for the container to set in the database
     */
    public void schedule (File           file,
                          MediaContainer parent,
                          string?        flag = null) {
        if (this.extractor == null) {
            warning (_("No metadata extractor available. Will not crawl."));

            return;
        }

        // Cancel a probably running harvester
        this.cancel (file);

        var task = new HarvestingTask (this.extractor,
                                       this.monitor,
                                       this.file_filter,
                                       file,
                                       parent,
                                       flag);
        task.cancellable = this.cancellable;
        task.completed.connect (this.on_file_harvested);
        this.tasks[file] = task;
        task.run ();
    }

    /**
     * Cancel a running meta-data extraction run
     *
     * @param file file cancel the current run for
     */
    public void cancel (File file) {
        if (this.tasks.has_key (file)) {
            var task = this.tasks[file];
            task.completed.disconnect (this.on_file_harvested);
            this.tasks.unset (file);
            task.cancel ();
        }
    }

    /**
     * Callback for finished harvester.
     *
     * Updates book-keeping hash.
     * @param state_machine HarvestingTask sending the event
     */
    private void on_file_harvested (StateMachine state_machine) {
        var task = state_machine as HarvestingTask;
        var file = task.origin;
        message (_("'%s' harvested"), file.get_uri ());

        this.tasks.unset (file);
    }

    /**
     * Construct positive filter from config
     *
     * Takes a list of file extensions from config, escapes them and builds a
     * regular expression to match against the files encountered.
     */
    private void create_file_filter () {
        try {
            var config = MetaConfig.get_default ();
            var extensions = config.get_string_list ("MediaExport",
                                                     "include-filter");

            // never trust user input
            string[] escaped_extensions = new string[0];
            foreach (var extension in extensions) {
                escaped_extensions += Regex.escape_string (extension);
            }

            var list = string.joinv ("|", escaped_extensions);
            this.file_filter = new Regex (
                                     "(%s)$".printf (list),
                                     RegexCompileFlags.CASELESS |
                                     RegexCompileFlags.OPTIMIZE);
        } catch (Error error) {
            this.file_filter = null;
        }
    }

    private void on_file_changed (File             file,
                                  File?            other,
                                  FileMonitorEvent event) {
        try {
            var cache = MediaCache.get_default ();
            switch (event) {
                case FileMonitorEvent.CREATED:
                case FileMonitorEvent.CHANGES_DONE_HINT:
                    var type = file.query_file_type (FileQueryInfoFlags.NONE,
                                                     this.cancellable);
                    if (type == FileType.DIRECTORY ||
                        this.file_filter == null ||
                        this.file_filter.match (file.get_uri ())) {
                        debug ("Trying to harvest %s because of %s",
                               file.get_uri (),
                               event.to_string ());
                        var id = MediaCache.get_id (file.get_parent ());
                        try {
                               var parent_container = cache.get_object (id)
                                            as MediaContainer;
                                assert (parent_container != null);

                                this.schedule (file, parent_container);
                        } catch (DatabaseError error) {
                            warning (_("Error fetching object '%s' from database: %s"),
                                     id,
                                     error.message);
                        }
                    }
                    break;
                case FileMonitorEvent.DELETED:
                    this.cancel (file);
                    try {
                        // the full object is fetched instead of simply calling
                        // exists because we need the parent to signalize the
                        // change
                        var id = MediaCache.get_id (file);
                        var obj = cache.get_object (id);

                        // it may be that files removed are files that are not
                        // in the database, because they're not media files
                        if (obj != null) {
                            cache.remove_object (obj);
                            if (obj.parent != null) {
                                obj.parent.updated ();
                            }
                        }
                    } catch (Error error) {
                        warning (_("Error removing object from database: %s"),
                                 error.message);
                    }
                    break;
                default:
                    break;
            }
        } catch (Error error) { }
    }
}
