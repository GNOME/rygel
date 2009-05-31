/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Gee;
using Sqlite;

public errordomain Rygel.MediaDBError {
    SQLITE_ERROR
}

public enum Rygel.MediaDBObjectType {
    CONTAINER,
    ITEM
}

public class Rygel.MediaDB : Object {
    private Database db;
    private const string schema_version = "1";
    private const string db_schema_v1 =
    "BEGIN;" +
    "CREATE TABLE Schema_Info (version TEXT NOT NULL); " +
    "CREATE TABLE Object_Type (id INTEGER PRIMARY KEY, " +
                              "desc TEXT NOT NULL);" +
    "CREATE TABLE Meta_Data (id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                            "size INTEGER NOT NULL, " +
                            "mime_type TEXT NOT NULL, " +
                            "width INTEGER, " +
                            "height INTEGER, " +
                            "class TEXT NOT NULL, " +
                            "title TEXT NOT NULL, " +
                            "author TEXT, " +
                            "album TEXT, " +
                            "date TEXT, " +
                            "bitrate INTEGER, " +
                            "sample_freq INTEGER, " +
                            "bits_per_sample INTEGER, " +
                            "channels INTEGER, " +
                            "track, " +
                            "color_depth);" +
    "CREATE TABLE Object (id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                         "upnp_id TEXT UNIQUE, " +
                         "type_fk INTEGER REFERENCES Object_Type(id), " +
                         "metadata_fk INTEGER REFERENCES Meta_Data(id) " +
                         "ON DELETE CASCADE);" +
    "CREATE TABLE Uri (object_fk INTEGER REFERENCES Object(id), "+
                      "uri TEXT NOT NULL);" +
    "INSERT INTO Object_Type (id, desc) VALUES (0, 'Container'); " +
    "INSERT INTO Object_Type (id, desc) VALUES (1, 'Item'); " +
    "INSERT INTO Schema_Info (version) VALUES ('" + MediaDB.schema_version +
                                                "'); " +
    "END;";

    private const string META_DATA_INSERT_STRING =
    "INSERT INTO Meta_Data " +
        "(size, mime_type, width, height, class, " +
         "title, author, album, date, bitrate, " +
         "sample_freq, bits_per_sample, channels, " +
         "track, color_depth) VALUES " +
         "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";

    private const string OBJECT_INSERT_STRING =
    "INSERT INTO Object (upnp_id, type_fk, metadata_fk) " +
        "VALUES (?,?,?);";

    private const string URI_INSERT_STRING =
    "INSERT INTO Uri (object_fk, uri) VALUES (?,?);";


    public MediaDB (string name) {
        var rc = Database.open (name, out this.db);
        if (rc != Sqlite.OK) {
            warning ("Failed to open database: %d, %s",
                     rc,
                     db.errmsg ());
            return;
        }

        weak string[] schema_info;
        int nrows;
        int ncolumns;
        // FIXME error message causes segfault
        rc = db.get_table ("SELECT version FROM Schema_Info;",
                           out schema_info,
                           out nrows,
                           out ncolumns,
                           null);

        if (rc == Sqlite.OK) {
            if (nrows == 1 && ncolumns == 1) {
                if (schema_info[1] == schema_version) {
                    debug ("Media DB schema has current version");
                } else {
                    debug ("Schema version differs... checking for upgrade");
                    // FIXME implement if necessary
                }
            } else {
                warning ("Incompatible schema... cannot proceed");
                db = null;
                return;
            }
        } else {
            debug ("Could not find schema version; checking for empty database...");
            rc = db.get_table ("SELECT * FROM sqlite_master",
                               out schema_info,
                               out nrows,
                               out ncolumns,
                               null);
            if (rc != Sqlite.OK) {
                warning ("Something weird going on: %s",
                         db.errmsg ());
                db = null;
                return;
            }

            if (nrows == 0) {
                debug ("Empty database, creating new schema version %s",
                       schema_version);
                if (!create_schema ()) {
                    return;
                }
            } else {
                warning ("Incompatible schema... cannot proceed");
                return;
            }
        }
    }

    public signal void item_added (string item_id);

    public void save_item (MediaItem item) throws Error {
        var rc = db.exec ("BEGIN;");
        try {
            var id = save_metadata (item);
            id = create_object (item, id);
            save_uris (item, id);
            rc = db.exec ("COMMIT;");
            if (rc == Sqlite.OK) {
                item_added (item.id);
            }
        } catch (Error error) {
            rc = db.exec ("ROLLBACK;");
        }
    }

    private int64 save_metadata (MediaItem item) throws Error {
        Statement statement;
        var rc = db.prepare_v2 (META_DATA_INSERT_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            statement.bind_int64 (1, item.size);
            statement.bind_text (2, item.mime_type);
            statement.bind_int (3, item.width);
            statement.bind_int (4, item.height);
            statement.bind_text (5, item.upnp_class);
            statement.bind_text (6, item.title);
            statement.bind_text (7, item.author);
            statement.bind_text (8, item.album);
            statement.bind_text (9, item.date);
            statement.bind_int (10, item.bitrate);
            statement.bind_int (11, item.sample_freq);
            statement.bind_int (12, item.bits_per_sample);
            statement.bind_int (13, item.n_audio_channels);
            statement.bind_int (14, item.track_number);
            statement.bind_int (15, item.color_depth);

            rc = statement.step ();
            if (rc == Sqlite.DONE || rc == Sqlite.OK) {
                return db.last_insert_rowid ();
            } else {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private int64 create_object (MediaItem item, int64 metadata_id) throws
                                                                        Error {
        Statement statement;

        var rc = db.prepare_v2 (OBJECT_INSERT_STRING,
                            -1,
                            out statement,
                            null);
        if (rc == Sqlite.OK) {
            statement.bind_text (1, item.id);
            statement.bind_int (2, MediaDBObjectType.ITEM);
            statement.bind_int64 (3, metadata_id);
            rc = statement.step ();
            if (rc == Sqlite.OK || rc == Sqlite.DONE) {
                return db.last_insert_rowid ();
            } else {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private void save_uris (MediaItem item, int64 object_id) throws Error {
        Statement statement;

        var rc = db.prepare_v2 (URI_INSERT_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            foreach (var uri in item.uris) {
                statement.bind_int64 (1, object_id);
                statement.bind_text (2, uri);
                rc = statement.step ();
                if (rc != Sqlite.OK && rc != Sqlite.DONE) {
                    throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
                }
                statement.reset ();
                statement.clear_bindings ();
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    /**
     * Create the current schema.
     *
     * If schema creation fails, schema will be rolled back
     * completely.
     *
     * @returns: true on success, false on failure
     */
    private bool create_schema () {
        var rc = db.exec (db_schema_v1);
        if (rc == Sqlite.OK) {
            debug ("Schema created");
            return true;
        } else {
            warning ("Could not create schema: %d, %s",
                     rc,
                     db.errmsg ());
            rc = db.exec ("ROLLBACK;");
            return false;
        }
    }

    public MediaItem? get_item (string item_id) {
        Statement statement;
        var rc = db.prepare_v2 ("SELECT size, mime_type, width, height, class, title, author, album, date, bitrate, sample_freq, bits_per_sample, channels, track, color_depth from Meta_Data join Object on Object.metadata_fk = Meta_Data.id WHERE Object.upnp_id = ?",
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            debug ("Trying to find item with id %s", item_id);
            statement.bind_text (1, item_id);
            while ((rc = statement.step ()) == Sqlite.ROW) {
                string title = statement.column_text (5);
                string upnp_class = statement.column_text (4);
                var item = new MediaItem (item_id, null, title, upnp_class);

                item.author = statement.column_text (6);
                item.album = statement.column_text (7);
                item.date = statement.column_text (8);
                item.mime_type = statement.column_text (1);

                item.size = (long)statement.column_int64 (0);
                item.bitrate = statement.column_int (9);

                item.sample_freq = statement.column_int (10);
                item.bits_per_sample = statement.column_int (11);
                item.n_audio_channels = statement.column_int (12);
                item.track_number = statement.column_int (13);

                item.width = statement.column_int (2);
                item.height = statement.column_int (3);
                item.color_depth = statement.column_int (14);

                return item;
            }
        }

        return null;
    }
}
