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

    /**
     * Create a new instance of the meta-data extraction manager.
     *
     * @param extractor instance of MetadataExtractor used for meta-data
     *                  extraction by this task
     * @param monitor intance of a RecursiveFileMonitor which is used to keep
     *                track of the file changes
     */
    public Harvester (MetadataExtractor    extractor,
                      RecursiveFileMonitor monitor) {
        this.extractor = extractor;
        this.monitor = monitor;
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
                           string?        flag   = null) {
        if (this.extractor == null) {
            warning (_("No Metadata extractor available. Will not crawl"));

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
        if (this.tasks.contains (file)) {
            var task = this.tasks[file];
            task.completed.disconnect (this.on_file_harvested);
            this.tasks.remove (file);
            task.cancellable.cancel ();
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

        this.tasks.remove (file);
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
}
