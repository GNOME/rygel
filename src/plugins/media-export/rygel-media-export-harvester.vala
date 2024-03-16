/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
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
using Gee;

/**
 * This class takes care of the book-keeping of running and finished
 * extraction tasks running within the media-export plugin
 */
internal class Rygel.MediaExport.Harvester : GLib.Object {
    private const uint FILE_CHANGE_DEFAULT_GRACE_PERIOD = 5;

    private HashMap<File, HarvestingTask> tasks;
    private HashMap<File, uint> extraction_grace_timers;
    private RecursiveFileMonitor monitor;
    private Cancellable cancellable;

    // Properties
    public ArrayList<File> locations { get; private set; }

    public signal void done ();

    /**
     * Create a new instance of the meta-data extraction manager.
     */
    public Harvester (Cancellable     cancellable,
                      ArrayList<File> locations) {
        this.cancellable = cancellable;
        this.locations = new ArrayList<File> ((EqualDataFunc<File>) File.equal);
        foreach (var file in locations) {
            if (file.query_exists ()) {
                this.locations.add (file);
            }
        }

        this.monitor = new RecursiveFileMonitor (cancellable);
        this.monitor.changed.connect (this.on_file_changed);

        this.tasks = new HashMap<File, HarvestingTask>
                                        ((HashDataFunc<File>) File.hash,
                                         (EqualDataFunc<File>) File.equal);
        this.extraction_grace_timers = new HashMap<File, uint>
                                        ((HashDataFunc<File>) File.hash,
                                         (EqualDataFunc<File>) File.equal);
    }

    /**
     * Check if a FileInfo is considered for extraction
     *
     * @param info a FileInfo
     * @return true if file should be extracted, false otherwise
     */
    public static bool is_eligible (File file, FileInfo info) {
        if (info.get_file_type () == FileType.DIRECTORY) {
            return !file.get_child (".nomedia").query_exists ();
        }

        // Just ignore dangling symlinks
        if (info.get_file_type () == FileType.SYMBOLIC_LINK) {
            var target = info.get_attribute_as_string (FileAttribute.STANDARD_SYMLINK_TARGET);
            if (!File.new_for_commandline_arg (target).query_exists ()) {
                return false;
            }
        }

        var is_supported_content_type =
            info.get_content_type ().has_prefix ("image/") ||
            info.get_content_type ().has_prefix ("video/") ||
            info.get_content_type ().has_prefix ("audio/") ||
            info.get_content_type () == "application/ogg" ||
            info.get_content_type () == "application/xml" ||
            info.get_content_type () == "text/xml" ||
            info.get_content_type () == "text/plain" ||
            info.get_content_type () == "application/x-cd-image";
        var cache = MediaCache.get_default ();
        var is_ignored = cache.is_ignored (file);

        if (is_ignored) {
            debug ("URI %s is not eligible due, it is ignored",
                   file.get_uri ());
        }

        return is_supported_content_type && ! is_ignored;
    }

    /**
     * Schedule rescan of all top-level locations known to the harvester.
     *
     * @param parent top-level container of the files
     */
    public void schedule_locations (MediaContainer parent) {
        foreach (var file in this.locations) {
            this.schedule (file, parent);
        }
    }

    /**
     * Put a file on queue for meta-data extraction
     *
     * @param file the file to investigate
     * @param parent container of the filer to be harvested
     */
    public void schedule (File           file,
                          MediaContainer parent) {
        this.extraction_grace_timers.unset (file);

        // Cancel a probably running harvester
        this.cancel (file);

        var task = new HarvestingTask (this.monitor,
                                       file,
                                       parent);
        task.cancellable = this.cancellable;
        task.completed.connect (this.on_file_harvested);
        this.tasks[file] = task;
        task.run.begin ();
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
        message (_("“%s” harvested"), file.get_uri ());

        this.tasks.unset (file);
        if (this.tasks.is_empty) {
            done ();
        }
    }

    private void on_file_changed (File             file,
                                  File?            other,
                                  FileMonitorEvent event) {
        try {
            switch (event) {
                case FileMonitorEvent.CREATED: {
                    var info = file.query_info (FileAttribute.STANDARD_TYPE,
                                                FileQueryInfoFlags.NONE,
                                                this.cancellable);

                    if (info.get_file_type () == FileType.DIRECTORY) {
                        this.on_changes_done (file);
                    }
                    break;
                }
                case FileMonitorEvent.CHANGES_DONE_HINT:
                    this.on_changes_done (file);
                    break;
                case FileMonitorEvent.DELETED:
                    this.on_file_removed (file);
                    break;
                default:
                    break;
            }
        } catch (Error error) {
            debug ("Failed to query information for %s: %s",
                   file.get_uri (),
                   error.message);
        }
    }

    private void on_file_added (File file) {
        debug ("Filesystem events settled for %s, scheduling extraction…",
               file.get_uri ());
        try {
            var cache = MediaCache.get_default ();
            var info = file.query_info (FileAttribute.STANDARD_TYPE + "," +
                                        FileAttribute.STANDARD_CONTENT_TYPE + "," +
                                        FileAttribute.STANDARD_SYMLINK_TARGET,
                                        FileQueryInfoFlags.NONE,
                                        this.cancellable);
            if (Harvester.is_eligible (file, info)) {
                var id = MediaCache.get_id (file.get_parent ());
                try {
                    var parent_container = cache.get_object (id)
                                        as MediaContainer;
                    this.schedule (file, parent_container);
                } catch (Database.DatabaseError error) {
                    warning (_("Error fetching object “%s” from database: %s"),
                            id,
                            error.message);
                }
            } else {
                debug ("%s is not eligible for extraction", file.get_uri ());
            }
        } catch (Error error) {
            warning (_("Failed to query info of a file %s: %s"),
                     file.get_uri (),
                     error.message);
        }
    }

    private void on_file_removed (File file) {
        var cache = MediaCache.get_default ();
        if (this.extraction_grace_timers.has_key (file)) {
            Source.remove (this.extraction_grace_timers[file]);
            this.extraction_grace_timers.unset (file);
        }

        this.cancel (file);
        try {
            // the full object is fetched instead of simply calling
            // exists because we need the parent to signal the
            // change
            var id = MediaCache.get_id (file);
            var object = cache.get_object (id);

            if (object != null && object.parent != null) {
                var parent = object.parent;

                if (parent is WritableDbContainer) {
                    var container = parent as WritableDbContainer;

                    container.remove_tracked (object);
                } else if (parent is TrackableDbContainer) {
                    // This should not be possible, but just to be sure.
                    var container = parent as TrackableContainer;

                    container.remove_child_tracked.begin (object);
                }
            } else {
                warning (_("Could not find object %s or its parent. Database is inconsistent"),
                         id);
            }
        } catch (Error error) {
            warning (_("Error removing object from database: %s"),
                     error.message);
        }
    }

    private void on_changes_done (File file) throws Error {
        if (file.get_basename ().has_prefix (".")) {
            return;
        }

        var period = FILE_CHANGE_DEFAULT_GRACE_PERIOD;
        try {
            var config = MetaConfig.get_default ();
            period = config.get_int ("MediaExport",
                                     "monitor-grace-timeout",
                                     0,
                                     500);
        } catch (Error error) { }


        if (this.extraction_grace_timers.has_key (file)) {
            Source.remove (this.extraction_grace_timers[file]);
        } else if (period > 0) {
            debug ("Starting grace timer for harvesting %s…",
                    file.get_uri ());
        }

        SourceFunc callback = () => {
            this.on_file_added (file);

            return false;
        };

        if (period > 0) {
            var timeout = Timeout.add_seconds (FILE_CHANGE_DEFAULT_GRACE_PERIOD,
                                               (owned) callback);
            this.extraction_grace_timers[file] = timeout;
        } else {
            Idle.add ((owned) callback);
        }
    }
}
