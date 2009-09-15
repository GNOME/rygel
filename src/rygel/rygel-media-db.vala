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
    SQLITE_ERROR,
    GENERAL_ERROR
}

public enum Rygel.MediaDBObjectType {
    CONTAINER,
    ITEM
}

/**
 * Persistent storage of media objects
 *
 * MediaDB is a sqlite3 backed persistent storage of media objects
 */
public class Rygel.MediaDB : Object {
    private Database db;
    private MediaDBObjectFactory factory;
    private const string schema_version = "4";
    private const string SCHEMA_STRING =
    "CREATE TABLE Schema_Info (version TEXT NOT NULL); " +
    "CREATE TABLE Object_Type (id INTEGER PRIMARY KEY, " +
                              "desc TEXT NOT NULL);" +
    "CREATE TABLE Meta_Data (id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                            "size INTEGER NOT NULL, " +
                            "mime_type TEXT NOT NULL, " +
                            "duration INTEGER, " +
                            "width INTEGER, " +
                            "height INTEGER, " +
                            "class TEXT NOT NULL, " +
                            "author TEXT, " +
                            "album TEXT, " +
                            "date TEXT, " +
                            "bitrate INTEGER, " +
                            "sample_freq INTEGER, " +
                            "bits_per_sample INTEGER, " +
                            "channels INTEGER, " +
                            "track INTEGER, " +
                            "color_depth INTEGER, " +
                            "object_fk TEXT UNIQUE CONSTRAINT " +
                                "object_fk_id REFERENCES Object(upnp_id) " +
                                    "ON DELETE CASCADE);" +
    "CREATE TABLE Object (parent TEXT CONSTRAINT parent_fk_id " +
                                "REFERENCES Object(upnp_id), " +
                          "upnp_id TEXT PRIMARY KEY, " +
                          "type_fk INTEGER CONSTRAINT type_fk_id " +
                                "REFERENCES Object_Type(id), " +
                          "title TEXT NOT NULL, " +
                          "timestamp INTEGER NOT NULL);" +
    "CREATE TABLE Uri (object_fk TEXT " +
                        "CONSTRAINT object_fk_id REFERENCES Object(upnp_id) "+
                            "ON DELETE CASCADE, " +
                      "uri TEXT NOT NULL);" +
    "INSERT INTO Object_Type (id, desc) VALUES (0, 'Container'); " +
    "INSERT INTO Object_Type (id, desc) VALUES (1, 'Item'); " +
    "INSERT INTO Schema_Info (version) VALUES ('" + MediaDB.schema_version +
                                                "'); ";

    private const string CREATE_TRIGGER_STRING =
    "CREATE TRIGGER trgr_delete_children " +
    "BEFORE DELETE ON Object " +
    "FOR EACH ROW BEGIN " +
        "UPDATE Object SET parent = NULL " +
            "WHERE Object.parent = OLD.upnp_id;" +
    "END;" +

    "CREATE TRIGGER trgr_delete_metadata " +
    "BEFORE DELETE ON Object " +
    "FOR EACH ROW BEGIN " +
        "DELETE FROM Meta_Data WHERE Meta_Data.object_fk = OLD.upnp_id; "+
    "END;" +

    "CREATE TRIGGER trgr_delete_uris " +
    "BEFORE DELETE ON Object " +
    "FOR EACH ROW BEGIN " +
        "DELETE FROM Uri WHERE Uri.object_fk = OLD.upnp_id;" +
    "END;";


    private const string INSERT_META_DATA_STRING =
    "INSERT INTO Meta_Data " +
        "(size, mime_type, width, height, class, " +
         "author, album, date, bitrate, " +
         "sample_freq, bits_per_sample, channels, " +
         "track, color_depth, duration, object_fk) VALUES " +
         "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

    private const string UPDATE_META_DATA_STRING =
    "UPDATE Meta_Data SET " +
         "size = ?, mime_type = ?, width = ?, height = ?, class = ?, " +
         "author = ?, album = ?, date = ?, bitrate = ?, " +
         "sample_freq = ?, bits_per_sample = ?, channels = ?, " +
         "track = ?, color_depth = ?, duration = ? " +
         "WHERE object_fk = ?";

    private const string INSERT_OBJECT_STRING =
    "INSERT INTO Object (upnp_id, title, type_fk, parent, timestamp) " +
        "VALUES (?,?,?,?,?)";

    private const string UPDATE_OBJECT_STRING =
    "UPDATE Object SET title = ?, timestamp = ? WHERE upnp_id = ?";

    private const string INSERT_URI_STRING =
    "INSERT INTO Uri (object_fk, uri) VALUES (?,?)";

    private const string DELETE_URI_STRING =
    "DELETE FROM Uri WHERE object_fk = ?";

    private const string GET_OBJECT_STRING =
    "SELECT type_fk, title, Meta_Data.size, Meta_Data.mime_type, " +
            "Meta_Data.width, Meta_Data.height, " +
            "Meta_Data.class, Meta_Data.author, Meta_Data.album, " +
            "Meta_Data.date, Meta_Data.bitrate, Meta_Data.sample_freq, " +
            "Meta_Data.bits_per_sample, Meta_Data.channels, " +
            "Meta_Data.track, Meta_Data.color_depth, Meta_Data.duration, " +
            "Object.parent " +
    "FROM Object LEFT OUTER JOIN Meta_Data " +
        "ON Object.upnp_id = Meta_Data.object_fk WHERE Object.upnp_id = ?";

    /**
     * This is the database query used to retrieve the children for a
     * given object.
     *
     * Sorting is as follows:
     *   - by type: containers first, then items if both are present
     *   - by upnp_class: items are sorted according to their class
     *   - by track: sorted by track
     *   - and after that alphabetically
     */
    private const string GET_CHILDREN_STRING =
    "SELECT type_fk, title, Meta_Data.size, Meta_Data.mime_type, " +
            "Meta_Data.width, Meta_Data.height, " +
            "Meta_Data.class, Meta_Data.author, Meta_Data.album, " +
            "Meta_Data.date, Meta_Data.bitrate, Meta_Data.sample_freq, " +
            "Meta_Data.bits_per_sample, Meta_Data.channels, " +
            "Meta_Data.track, Meta_Data.color_depth, Meta_Data.duration, " +
            "upnp_id, Object.parent, Object.timestamp " +
    "FROM Object LEFT OUTER JOIN Meta_Data " +
        "ON Object.upnp_id = Meta_Data.object_fk " +
    "WHERE Object.parent = ? " +
        "ORDER BY type_fk ASC, " +
                 "Meta_Data.class ASC, " +
                 "Meta_Data.track ASC, " +
                 "title ASC " +
    "LIMIT ?,?";

    private const string URI_GET_STRING =
    "SELECT uri FROM Uri WHERE Uri.object_fk = ?";

    private const string CHILDREN_COUNT_STRING =
    "SELECT COUNT(upnp_id) FROM Object WHERE Object.parent = ?";

    private const string OBJECT_EXISTS_STRING =
    "SELECT COUNT(upnp_id), timestamp FROM Object WHERE Object.upnp_id = ?";

    private const string OBJECT_DELETE_STRING =
    "DELETE FROM Object WHERE Object.upnp_id = ?";

    private const string SWEEPER_STRING =
    "DELETE FROM Object WHERE parent IS NULL AND Object.upnp_id != '0'";

    private const string GET_CHILD_ID_STRING =
    "SELECT upnp_id FROM OBJECT WHERE parent = ?";

    private const string UPDATE_V3_V4_STRING_1 =
    "ALTER TABLE Meta_Data ADD object_fk TEXT";

    private const string UPDATE_V3_V4_STRING_2 =
    "UPDATE Meta_Data SET object_fk = " +
        "(SELECT upnp_id FROM Object WHERE metadata_fk = Meta_Data.id)";

    private const string UPDATE_V3_V4_STRING_3 =
    "ALTER TABLE Object ADD timestamp INTEGER";

    private const string UPDATE_V3_V4_STRING_4 =
    "UPDATE Object SET timestamp = 0";

    private void update_v3_v4 () {
        if (db.exec ("BEGIN") == Sqlite.OK &&
            db.exec (UPDATE_V3_V4_STRING_1) == Sqlite.OK &&
            db.exec (UPDATE_V3_V4_STRING_2) == Sqlite.OK &&
            db.exec (UPDATE_V3_V4_STRING_3) == Sqlite.OK &&
            db.exec (UPDATE_V3_V4_STRING_4) == Sqlite.OK &&
            db.exec (CREATE_TRIGGER_STRING) == Sqlite.OK &&
            db.exec ("UPDATE Schema_Info SET version = " +
                     schema_version) == Sqlite.OK) {
            db.exec ("COMMIT");
        } else {
            db.exec ("ROLLBACK");
            warning ("Database upgrade failed: %s", db.errmsg());
            db = null;
        }
    }

    private void open_db (string name) {
        var dirname = Path.build_filename (Environment.get_user_cache_dir (),
                                           Environment.get_prgname ());
        DirUtils.create_with_parents (dirname, 0750);
        var db_file = Path.build_filename (dirname, "%s.db".printf (name));
        debug ("Using database file %s", db_file);
        var rc = Database.open (db_file, out this.db);
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
                    int old_version = schema_info[1].to_int();
                    int current_version = schema_version.to_int();
                    if (old_version < current_version) {
                        debug ("Older schema detected. Upgrading...");
                        switch (old_version) {
                            case 3:
                                update_v3_v4 ();
                                break;
                            default:
                                warning ("Cannot upgrade");
                                db = null;
                                break;
                        }
                    } else {
                        warning ("The version \"%d\" of the detected database" +
                                 " is newer than our supported version \"%d\"",
                                old_version, current_version);
                        db = null;
                    }
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
                this.db = null;
                return;
            }

            if (nrows == 0) {
                debug ("Empty database, creating new schema version %s",
                       schema_version);
                if (!create_schema ()) {
                    this.db = null;
                    return;
                }
            } else {
                warning ("Incompatible schema... cannot proceed");
                this.db = null;
                return;
            }
        }
    }

    private MediaDB (string name, MediaDBObjectFactory factory) {
        open_db (name);
        this.factory = factory;
    }

    public static MediaDB? create (string name) throws MediaDBError {
        var instance = new MediaDB (name, new MediaDBObjectFactory());
        if (instance.db != null) {
            return instance;
        }

        throw new MediaDBError.GENERAL_ERROR("Invalid database");
    }

    public static MediaDB? create_with_factory (string               name,
                                                MediaDBObjectFactory factory)
                                                throws MediaDBError          {
        var instance = new MediaDB (name, new MediaDBObjectFactory());
        if (instance.db != null) {
            return instance;
        }

        throw new MediaDBError.GENERAL_ERROR("Invalid database");
    }

    private bool sweeper () {
        debug ("Running sweeper");
        var rc = db.exec (SWEEPER_STRING);
        if (rc != Sqlite.OK) {
            warning ("Failed to sweep database");
            return false;
        } else {
            // if there have been any objects deleted, their children
            // will have nullified parents by the trigger, so we reschedule
            // the idle sweeper
            var changes = db.changes ();
            debug ("Changes in sweeper: %d", changes);
            return changes != 0;
        }
    }

    public signal void item_deleted (string item_id);
    public signal void item_added (string item_id);
    public signal void item_updated (string item_id);

    public signal void container_added (string container_id);
    public signal void container_removed (string container_id);
    public signal void container_updated (string container_id);

    public void delete_by_id (string id) throws MediaDBError {
        Statement statement;

        var rc = db.prepare_v2 ("DELETE FROM Object WHERE upnp_id = ?",
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            rc = statement.step ();
            if (rc == Sqlite.DONE || rc == Sqlite.OK) {
                item_deleted (id);
                Idle.add (this.sweeper);
            }
        } else {
            warning ("Failed to prepare delete of object %s: %s",
                     id,
                     db.errmsg ());
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }


    public void delete_object (MediaObject obj) throws MediaDBError {
        this.delete_by_id (obj.id);
    }

    public void save_object (MediaObject obj) throws Error {
        if (obj is MediaItem) {
            save_item ((MediaItem)obj);
        } else if (obj is MediaContainer) {
            save_container ((MediaContainer)obj);
        } else {
            throw new MediaDBError.GENERAL_ERROR ("Invalid object type");
        }
    }

    private void save_container (MediaContainer container) throws Error {
        var rc = db.exec ("BEGIN");
        try {
            create_object (container);
            save_uris (container);
            rc = db.exec ("COMMIT");
        } catch (Error error) {
            rc = db.exec ("ROLLBACK");
        }
    }

    private void save_item (MediaItem item) throws Error {
        var rc = db.exec ("BEGIN;");
        try {
            save_metadata (item);
            create_object (item);
            save_uris (item);
            rc = db.exec ("COMMIT;");
            if (rc == Sqlite.OK) {
                item_added (item.id);
            }
        } catch (Error error) {
            warning ("Failed to add item with id %s: %s",
                     item.id,
                     error.message);
            rc = db.exec ("ROLLBACK;");
        }
    }


    public void update_object (MediaObject obj) {
        var rc = db.exec ("BEGIN");
        try {
            delete_uris (obj);
            if (obj is MediaItem) {
                save_metadata ((MediaItem)obj, UPDATE_META_DATA_STRING);
            }
            update_object_internal (obj);
            save_uris (obj);
            rc = db.exec ("COMMIT");
            if (rc == Sqlite.OK) {
                item_updated (obj.id);
            }
        } catch (Error error) {
            warning ("Failed to add item with id %s: %s",
                     obj.id,
                     error.message);
            rc = db.exec ("ROLLBACK");
        }
    }

    private void update_object_internal (MediaObject obj) throws Error {
        Statement statement;
        var rc = db.prepare_v2 (UPDATE_OBJECT_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, obj.title) != Sqlite.OK ||
                statement.bind_int64 (2, (int64) obj.modified) != Sqlite.OK ||
                statement.bind_text (3, obj.id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            rc = statement.step ();
            if (rc != Sqlite.DONE && rc != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private void delete_uris (MediaObject obj) throws Error {
        Statement statement;
        var rc = db.prepare_v2 (DELETE_URI_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, obj.id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            rc = statement.step ();
            if (rc != Sqlite.DONE && rc != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private void save_metadata (MediaItem item,
                                string sql = INSERT_META_DATA_STRING)
                                                                throws Error {
        Statement statement;
        var rc = db.prepare_v2 (sql,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_int64 (1, item.size) != Sqlite.OK ||
                statement.bind_text (2, item.mime_type) != Sqlite.OK ||
                statement.bind_int (3, item.width) != Sqlite.OK ||
                statement.bind_int (4, item.height) != Sqlite.OK ||
                statement.bind_text (5, item.upnp_class) != Sqlite.OK ||
                statement.bind_text (6, item.author) != Sqlite.OK ||
                statement.bind_text (7, item.album) != Sqlite.OK ||
                statement.bind_text (8, item.date) != Sqlite.OK ||
                statement.bind_int (9, item.bitrate) != Sqlite.OK ||
                statement.bind_int (10, item.sample_freq) != Sqlite.OK ||
                statement.bind_int (11, item.bits_per_sample) != Sqlite.OK ||
                statement.bind_int (12, item.n_audio_channels) != Sqlite.OK ||
                statement.bind_int (13, item.track_number) != Sqlite.OK ||
                statement.bind_int (14, item.color_depth) != Sqlite.OK ||
                statement.bind_int64 (15, item.duration) != Sqlite.OK ||
                statement.bind_text (16, item.id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }

            rc = statement.step ();
            if (rc != Sqlite.DONE && rc != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private void create_object (MediaObject item) throws Error {
        Statement statement;

        var rc = db.prepare_v2 (INSERT_OBJECT_STRING,
                            -1,
                            out statement,
                            null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, item.id) != Sqlite.OK ||
                statement.bind_int64 (5, (int64) item.modified) != Sqlite.OK ||
                statement.bind_text (2, item.title) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }

            if (item is MediaItem) {
                rc = statement.bind_int (3, MediaDBObjectType.ITEM);
            } else if (item is MediaObject) {
                rc = statement.bind_int (3, MediaDBObjectType.CONTAINER);
            } else {
                throw new MediaDBError.GENERAL_ERROR ("Invalid object type");
            }

            if (rc != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }

            if (item.parent == null) {
                rc = statement.bind_null (5);
            } else {
                rc = statement.bind_text (4, item.parent.id);
            }
            if (rc != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }

            rc = statement.step ();
            if (rc != Sqlite.OK && rc != Sqlite.DONE) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private void save_uris (MediaObject obj) throws Error {
        Statement statement;

        var rc = db.prepare_v2 (INSERT_URI_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            foreach (var uri in obj.uris) {
                if (statement.bind_text (1, obj.id) != Sqlite.OK ||
                    statement.bind_text (2, uri) != Sqlite.OK) {
                    throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
                }
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
        var rc = db.exec ("BEGIN");
        if (rc == Sqlite.OK) {
            rc = db.exec (SCHEMA_STRING);
            if (rc == Sqlite.OK) {
                debug ("succeeded in schema creation");
                rc = db.exec (CREATE_TRIGGER_STRING);
                if (rc == Sqlite.OK) {
                    debug ("succeeded in trigger creation");
                    rc = db.exec ("COMMIT");
                    if (rc == Sqlite.OK) {
                        return true;
                    } else {
                        warning ("Failed to commit schema: %d %s",
                                 rc,
                                 db.errmsg ());
                    }
                } else {
                    warning ("Failed to create triggers: %d %s",
                             rc,
                             db.errmsg ());
                }
            } else {
                warning ("Failed to create tables: %d %s",
                         rc,
                         db.errmsg ());
            }
        } else {
            warning ("Failed to start transaction: %d %s",
                     rc,
                     db.errmsg ());
        }

        db.exec ("ROLLBACK");
        return false;

   }

    private void add_uris (MediaObject obj) throws MediaDBError {
        Statement statement;

        var rc = db.prepare_v2 (URI_GET_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, obj.id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }

            while ((rc = statement.step ()) == Sqlite.ROW) {
                if (obj is MediaItem)
                    ((MediaItem) obj).add_uri (statement.column_text (0), null);
                else
                    obj.uris.add (statement.column_text (0));
            }
        } else {
            warning ("Failed to get uris for obj %s: %s",
                     obj.id,
                     db.errmsg ());
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }
    }

    private MediaObject? get_object_from_statement (MediaContainer? parent,
                                                    string object_id,
                                                    Statement statement) {
        MediaObject obj = null;
        switch (statement.column_int (0)) {
            case 0:
                // this is a container
                obj = factory.get_container (this,
                        object_id,
                        statement.column_text (1),
                        0);
                break;
            case 1:
                // this is an item
                obj = factory.get_item (this,
                        parent,
                        object_id,
                        statement.column_text (1),
                        statement.column_text (6));
                fill_item (statement, (MediaItem)obj);
                break;
            default:
                assert_not_reached ();
                break;
        }

        try {
            if (obj != null) {
                obj.modified = statement.column_int64 (18);
                add_uris (obj);
            }
        } catch (MediaDBError err) {
            warning ("Failed to load uris from database: %s", err.message);
            obj = null;
        }
        return obj;
    }

    public MediaObject? get_object (string object_id) throws MediaDBError {
        MediaObject obj = null;
        Statement statement;

        // decide what kind of object this is
        var rc = db.prepare_v2 (GET_OBJECT_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, object_id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }

            while ((rc = statement.step ()) == Sqlite.ROW) {
                MediaContainer parent = null;
                var parent_id = statement.column_text (17);
                if (parent_id != null) {
                    parent = (MediaContainer) get_object (
                                    statement.column_text (17));
                } else {
                    if (statement.column_text (0) != "0") {
                        warning ("Inconsitent database; non-root element " +
                                 "without parent found. Id is %s",
                                 statement.column_text (0));
                    }
                }
                obj = get_object_from_statement ((MediaContainer) parent,
                                                 object_id,
                                                 statement);
                obj.parent_ref = (MediaContainer) parent;
                obj.parent = obj.parent_ref;
                break;
            }
        } else {
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }

        return obj;
    }

    private void fill_item (Statement statement, MediaItem item) {
        item.author = statement.column_text (7);
        item.album = statement.column_text (8);
        item.date = statement.column_text (9);
        item.mime_type = statement.column_text (3);
        item.duration = (long)statement.column_int64 (16);

        item.size = (long)statement.column_int64 (2);
        item.bitrate = statement.column_int (10);

        item.sample_freq = statement.column_int(11);
        item.bits_per_sample = statement.column_int (12);
        item.n_audio_channels = statement.column_int (13);
        item.track_number = statement.column_int (14);

        item.width = statement.column_int (4);
        item.height = statement.column_int (5);
        item.color_depth = statement.column_int (15);
    }

    public ArrayList<string> get_child_ids (string container_id)
                                                         throws MediaDBError {
        ArrayList<string> children = new ArrayList<string> (str_equal);
        Statement statement;

        var rc = db.prepare_v2 (GET_CHILD_ID_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, container_id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            while ((rc = statement.step ()) == Sqlite.ROW) {
                children.add (statement.column_text (0));
            }
        } else {
            warning ("Failed to get children for obj %s: %s",
                     container_id,
                     db.errmsg ());
            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }

        return children;
    }

    public int get_child_count (string container_id) throws MediaDBError {
        Statement statement;
        int count = 0;
        var rc = db.prepare_v2 (CHILDREN_COUNT_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, container_id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            while ((rc = statement.step ()) == Sqlite.ROW) {
                count = statement.column_int (0);
                break;
            }
        } else {
            warning ("Could not get child count for object %s: %s",
                     container_id,
                     db.errmsg ());

            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }

        return count;
    }

    public bool exists (string object_id, out int64 timestamp)
                                                          throws MediaDBError {
        Statement statement;
        bool exists = false;
        var rc = db.prepare_v2 (OBJECT_EXISTS_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, object_id) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            while ((rc = statement.step ()) == Sqlite.ROW) {
                exists = statement.column_int (0) == 1;
                timestamp = statement.column_int64 (1);
                break;
            }
        } else {
            warning ("Could not get child count for object %s: %s",
                     object_id,
                     db.errmsg ());

            throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
        }

        return exists;
    }


    public Gee.ArrayList<MediaObject> get_children (string container_id,
                                                      uint offset,
                                                      uint max_count) {
        Statement statement;
        Gee.ArrayList<MediaObject> children =
                                            new Gee.ArrayList<MediaObject> ();
        var rc = db.prepare_v2 (GET_CHILDREN_STRING,
                                -1,
                                out statement,
                                null);
        if (rc == Sqlite.OK) {
            if (statement.bind_text (1, container_id) != Sqlite.OK ||
                statement.bind_int64 (2, (int64) offset) != Sqlite.OK ||
                statement.bind_int64 (3, (int64) max_count) != Sqlite.OK) {
                throw new MediaDBError.SQLITE_ERROR (db.errmsg ());
            }
            while ((rc = statement.step ()) == Sqlite.ROW) {
                var child_id = statement.column_text (17);
                try {
                    var parent = get_object (statement.column_text (18));
                    children.add (get_object_from_statement
                    ((MediaContainer)parent, child_id, statement));
                    children[children.size - 1].parent = (MediaContainer)parent;
                    children[children.size - 1].parent_ref = (MediaContainer)parent;
                } catch (MediaDBError err) {
                    warning ("Could not get parent object: %s", err.message);
                }
            }
        }

        return children;
    }
}
