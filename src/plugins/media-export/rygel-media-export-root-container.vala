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

internal class Rygel.MediaExportDynamicContainer : Rygel.MediaDBContainer {
    public const string ID = "DynamicContainerId";

    public MediaExportDynamicContainer (MediaDB        media_db,
                                        MediaContainer parent) {
        base (media_db, ID, "Dynamic");
        this.parent = parent;
    }

    public Gee.List<string> get_uris () {
        var result = new ArrayList<string> ();

        var children = this.media_db.get_children (this.id, -1, -1);
        if (children != null) {
            foreach (var child in children) {
                result.add_all (child.uris);
            }
        }

        return result;
    }
}

/**
 * Represents the root container.
 */
public class Rygel.MediaExportRootContainer : Rygel.MediaDBContainer {
    private MetadataExtractor extractor;
    private HashMap<File, MediaExportHarvester> harvester;
    private MediaExportRecursiveFileMonitor monitor;
    private MediaExportDBusService service;
    private MediaExportDynamicContainer dynamic_elements;

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

        var dbus_uris = this.dynamic_elements.get_uris ();
        if (dbus_uris != null) {
            uris.add_all (dbus_uris);
        }

        return uris;
    }

    public static MediaContainer get_instance() {
        if (MediaExportRootContainer.instance == null) {
            try {
                var db = MediaDB.create ("media-export");
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
        this.harvest (file, this.dynamic_elements);
    }

    public void remove_uri (string uri) {
        var file = File.new_for_commandline_arg (uri);
        var id = Checksum.compute_for_string (ChecksumType.MD5,
                                              file.get_uri ());

        try {
            this.media_db.remove_by_id (id);
        } catch (Error e) {
            warning ("Failed to remove uri: %s", e.message);
        }
    }

    public string[] get_dynamic_uris () {
        string[] result = new string[0];
        var dynamic_uris = this.dynamic_elements.get_uris ();

        // copy by hand, to_array does not work due to
        // vala bug 568972
        foreach (string uri in dynamic_uris) {
            result += uri;
        }

        return result;
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
        this.dynamic_elements = new MediaExportDynamicContainer (db, this);

        int64 timestamp;
        if (!this.media_db.exists ("0", out timestamp)) {
            try {
                media_db.save_object (this);
            } catch (Error error) {
                // do nothing
            }
        }

        if (!this.media_db.exists ("DynamicContainerId", out timestamp)) {
            try {
                media_db.save_object (this.dynamic_elements);
            } catch (Error error) {
            }
        }

        ArrayList<string> ids;
        try {
            ids = media_db.get_child_ids ("0");
        } catch (MediaDBError e) {
            ids = new ArrayList<string>();
        }

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
            if (id == MediaExportDynamicContainer.ID)
                continue;

            debug ("Id %s no longer in config, deleting...",
                   id);
            try {
                this.media_db.remove_by_id (id);
            } catch (MediaDBError e) {
                warning ("Failed to remove entry: %s", e.message);
            }
        }

        this.updated ();
    }

    private void on_file_harvested (File file) {
        this.harvester.remove (file);
    }

    private void harvest (File file, MediaContainer parent = this) {
        if (!this.harvester.contains (file)) {
            var harvester = new MediaExportHarvester (parent,
                                                      this.media_db,
                                                      this.extractor,
                                                      this.monitor);
            harvester.harvested.connect (this.on_file_harvested);
            this.harvester[file] = harvester;
            harvester.harvest (file);
        } else {
            warning ("%s already scheduled for harvesting. Check config " +
                     "for duplicates.",
                     file.get_uri ());
        }
    }

    private void on_file_changed (File             file,
                                  File?            other,
                                  FileMonitorEvent event) {
        switch (event) {
            case FileMonitorEvent.CREATED:
            case FileMonitorEvent.CHANGES_DONE_HINT:
                var parent = file.get_parent ();
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      parent.get_uri ());
                var parent_container = this.media_db.get_object (id);
                if (parent_container != null) {
                    this.harvest (file, (MediaContainer)parent_container);
                } else {
                    assert_not_reached ();
                }
                break;
            case FileMonitorEvent.DELETED:
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      file.get_uri ());

                // the full object is fetched instead of simply calling exists
                // because we need the parent to signalize the change
                var obj = this.media_db.get_object (id);

                // it may be that files removed are files that are not
                // in the database, because they're not media files
                if (obj != null) {
                    this.media_db.remove_object (obj);
                    if (obj.parent != null) {
                        obj.parent.updated ();
                    }
                }
                break;
            default:
                break;
        }
    }
}
