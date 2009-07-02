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

/**
 * Represents the root container.
 */
public class Rygel.MediaExportRootContainer : Rygel.MediaDBContainer {
    private MetadataExtractor extractor;
    private HashMap<File, MediaExportHarvester> harvester;
    private MediaExportRecursiveFileMonitor monitor;
    private MediaExportDBusService service;

    private static MediaContainer instance = null;

    private ArrayList<string> get_uris () {
        ArrayList<string> uris;

        var config = MetaConfig.get_default ();

        try {
            uris = config.get_string_list ("MediaExport", "uris");
        } catch (Error error) {
            uris = new ArrayList<string> ();
        }

        // either an error occured or the gconf key is not set
        if (uris.size == 0) {
            debug("Nothing configured, using XDG special directories");
            var uri = Environment.get_user_special_dir (UserDirectory.MUSIC);
            if (uri != null)
                uris.add (uri);

            uri = Environment.get_user_special_dir (UserDirectory.PICTURES);
            if (uri != null)
                uris.add (uri);

            uri = Environment.get_user_special_dir (UserDirectory.VIDEOS);
            if (uri != null)
                uris.add (uri);
        }

        return uris;
    }

    public static MediaContainer get_instance() {
        if (MediaExportRootContainer.instance == null) {
            try {
                var db = MediaDB.create("media-export");
                MediaExportRootContainer.instance =
                                             new MediaExportRootContainer (db);
            } catch (MediaDBError err) {
                warning("Failed to create instance of database");
                MediaExportRootContainer.instance = new NullContainer ();
            }
        }

        return MediaExportRootContainer.instance;
    }

    public void add_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        this.harvest (file);
    }

    public void remove_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        var id = Checksum.compute_for_string (ChecksumType.MD5,
                                              file.get_uri ());
        this.media_db.delete_by_id (id);
    }


    /**
     * Create a new root container.
     */
    private MediaExportRootContainer (MediaDB db) {
        base (db, "0", "MediaExportRoot");

        this.extractor = new MetadataExtractor ();

        this.harvester = new HashMap<File,MediaExportHarvester> (file_hash,
                                                                 file_equal);

        this.monitor = new MediaExportRecursiveFileMonitor (null);
        this.monitor.changed.connect (this.on_file_changed);

        this.service = new MediaExportDBusService (this);

        try {
            media_db.save_object (this);
        } catch (Error error) {
        }

        var ids = media_db.get_child_ids ("0");
        var uris = get_uris ();
        foreach (var uri in uris) {
            var file = File.new_for_commandline_arg (uri);
            if (file.query_exists (null)) {
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      file.get_uri ());
                ids.remove (id);
                this.harvest (file);
            }
        }
        foreach (var id in ids) {
            debug ("Id %s no longer in config, deleting...",
                   id);
            this.media_db.delete_by_id (id);
        }
        this.updated ();
    }

    private void on_file_harvested (File file) {
        this.harvester.remove (file);
    }

    private void harvest (File file, MediaContainer parent = this) {
        var harvest = new MediaExportHarvester (parent,
                                                this.media_db,
                                                this.extractor,
                                                this.monitor);
        harvest.harvested.connect (this.on_file_harvested);
        this.harvester[file] = harvest;
        harvest.harvest (file);
    }

    private void on_file_changed (File             file,
                                  File?            other,
                                  FileMonitorEvent event) {
        switch (event) {
            case FileMonitorEvent.CREATED:
                var parent = file.get_parent ();
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      parent.get_uri ());
                var parent_container = this.media_db.get_object (id);
                if (parent_container != null) {
                    this.harvest (file, (MediaContainer)parent_container);
                } else {
                    // This should not happen
                }
                break;
            case FileMonitorEvent.CHANGES_DONE_HINT:
                break;
            case FileMonitorEvent.DELETED:
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      file.get_uri ());
                var obj = this.media_db.get_object (id);

                // it may be that files removed are files that are not
                // in the database, because they're not media files
                if (obj != null) {
                    this.media_db.delete_object (obj);
                    if (obj.parent != null) {
                        parent.updated ();
                    }
                }
                break;
            default:
                break;
        }
    }
}
