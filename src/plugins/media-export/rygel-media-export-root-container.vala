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
public class Rygel.MediaExportRootContainer : MediaContainer {
    private MediaDB media_db;
    private DatabaseBackedMediaContainer root_container;
    private MetadataExtractor extractor;
    private Gee.ArrayList<MediaExportHarvester> harvester;

    public override void get_children (uint offset,
                                       uint max_count,
                                       Cancellable? cancellable,
                                       AsyncReadyCallback callback)
    {
        this.root_container.get_children (offset,
                                          max_count,
                                          cancellable,
                                          callback);
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                    AsyncResult res)
                                                    throws GLib.Error {
        return this.root_container.get_children_finish (res);
    }

    public override void find_object (string id,
                                      Cancellable? cancellable,
                                      AsyncReadyCallback callback) {
        this.root_container.find_object (id,
                                         cancellable,
                                         callback);
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws GLib.Error {
        return this.root_container.find_object_finish (res);
    }

    /**
     * Create a new root container.
     */
    public MediaExportRootContainer () {
        base.root ("MediaExportRoot", 0);
        var media_db_path = Path.build_filename (
                                            Environment.get_user_cache_dir (),
                                            Environment.get_prgname (),
                                            "media-export.db");

        debug("Using media database %s", media_db_path);

        this.media_db = new MediaDB(media_db_path);
        this.extractor = new MetadataExtractor ();


        this.root_container = new DatabaseBackedMediaContainer (this.media_db,
                                                                "0",
                                                                "MediaExportRoot");

        this.harvester = new Gee.ArrayList<MediaExportHarvester> ();
        ArrayList<string> uris;

        var config = Rygel.MetaConfig.get_default ();

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

        foreach (var uri in uris) {
            var file = File.new_for_commandline_arg (uri);
            if (file.query_exists (null)) {
                var id = Checksum.compute_for_string (ChecksumType.MD5,
                                                      file.get_uri ());
                if (!this.media_db.exists (id)) {
                    var harvest =
                        new MediaExportHarvester (this.root_container, media_db,
                                extractor);
                    this.harvester.add (harvest);
                    harvest.harvest (file);
                } else {
                    this.child_count++;
                    this.updated ();
                }
            }
        }
    }
}
