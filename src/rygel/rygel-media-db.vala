/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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
using Sqlite;

public errordomain Rygel.MediaDBError {
    SQLITE_ERROR,
    GENERAL_ERROR,
    INVALID_TYPE
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

    private const string DELETE_BY_ID_STRING =
    "DELETE FROM Object WHERE upnp_id = ?";

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
        try {
            GLib.Value[] values = { schema_version };
            db.begin ();
            db.exec (UPDATE_V3_V4_STRING_1);
            db.exec (UPDATE_V3_V4_STRING_2);
            db.exec (UPDATE_V3_V4_STRING_3);
            db.exec (UPDATE_V3_V4_STRING_4);
            db.exec (CREATE_TRIGGER_STRING);
            db.exec ("UPDATE Schema_Info SET version = ?", values);
            db.commit ();
        } catch (DatabaseError err) {
            db.rollback ();
            warning ("Database upgrade failed: %s", err.message);
            db = null;
        }
    }

    private void open_db (string name) {
        this.db = new Rygel.Database (name);
        weak string[] schema_info;
        int nrows;
        int ncolumns;
        // FIXME error message causes segfault
        var rc = db.get_table ("SELECT version FROM Schema_Info;",
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
        var instance = new MediaDB (name, factory);
        if (instance.db != null) {
            return instance;
        }

        throw new MediaDBError.GENERAL_ERROR("Invalid database");
    }

    private bool sweeper () {
        try {
            debug ("Running sweeper");
            db.exec (SWEEPER_STRING);
            // if there have been any objects deleted, their children
            // will have nullified parents by the trigger, so we reschedule
            // the idle sweeper
            var changes = db.changes ();
            debug ("Changes in sweeper: %d", changes);
            return changes != 0;
        } catch (DatabaseError err) {
            warning ("Failed to sweep database");
            return false;
        }
    }

    public signal void object_added (string object_id);
    public signal void object_removed (string object_id);
    public signal void object_updated (string object_id);

    public signal void item_removed (string item_id);
    public signal void item_added (string item_id);
    public signal void item_updated (string item_id);

    public signal void container_added (string container_id);
    public signal void container_removed (string container_id);
    public signal void container_updated (string container_id);

    public void remove_by_id (string id) throws DatabaseError {
        GLib.Value[] values = { id };
        this.db.exec (DELETE_BY_ID_STRING, values);
        object_removed (id);
        Idle.add (this.sweeper);
    }


    public void remove_object (MediaObject obj) throws DatabaseError, MediaDBError {
        this.remove_by_id (obj.id);
        if (obj is MediaItem)
            item_removed (obj.id);
        else if (obj is MediaContainer)
            container_removed (obj.id);
        else
            throw new MediaDBError.INVALID_TYPE ("Invalid object type");
    }

    public void save_object (MediaObject obj) throws Error {
        if (obj is MediaItem) {
            save_item ((MediaItem)obj);
        } else if (obj is MediaContainer) {
            save_container ((MediaContainer)obj);
        } else {
            throw new MediaDBError.INVALID_TYPE ("Invalid object type");
        }
    }

    public void save_container (MediaContainer container) throws Error {
        try {
            db.begin ();
            create_object (container);
            save_uris (container);
            db.commit ();
            object_added (container.id);
            container_added (container.id);
        } catch (DatabaseError err) {
            db.rollback ();
            throw err;
        }
    }

    public void save_item (MediaItem item) throws Error {
        try {
            db.begin ();
            save_metadata (item);
            create_object (item);
            save_uris (item);
            db.commit ();
            object_added (item.id);
            item_added (item.id);
        } catch (DatabaseError error) {
            warning ("Failed to add item with id %s: %s",
                     item.id,
                     error.message);
            db.rollback ();
            throw error;
        }
    }


    public void update_object (MediaObject obj) throws Error {
        try {
            db.begin ();
            remove_uris (obj);
            if (obj is MediaItem) {
                save_metadata ((MediaItem)obj, UPDATE_META_DATA_STRING);
            }
            update_object_internal (obj);
            save_uris (obj);
            db.commit ();
            object_updated (obj.id);
            if (obj is MediaItem)
                item_updated (obj.id);
            else if (obj is MediaContainer)
                container_updated (obj.id);
        } catch (Error error) {
            warning ("Failed to add item with id %s: %s",
                     obj.id,
                     error.message);
            db.rollback ();
            throw error;
        }
    }

    private void update_object_internal (MediaObject obj) throws Error {
        GLib.Value[] values = { obj.title, (int64) obj.modified, obj.id };
        this.db.exec (UPDATE_OBJECT_STRING, values);
    }

    private void remove_uris (MediaObject obj) throws Error {
        GLib.Value[] values = { obj.id };
        this.db.exec (DELETE_URI_STRING, values);
    }

    private void save_metadata (MediaItem item,
                                string sql = INSERT_META_DATA_STRING)
                                                                throws Error {
        GLib.Value[] values = { item.size,
                                item.mime_type,
                                item.width,
                                item.height,
                                item.upnp_class,
                                item.author,
                                item.album,
                                item.date,
                                item.bitrate,
                                item.sample_freq,
                                item.bits_per_sample,
                                item.n_audio_channels,
                                item.track_number,
                                item.color_depth,
                                item.duration,
                                item.id };
        this.db.exec (sql, values);
    }

    private void create_object (MediaObject item) throws Error {
        GLib.Value[] values = { item.id,
                                item.title,
                                (item is MediaItem)
                                           ? (int) MediaDBObjectType.ITEM
                                           : (int) MediaDBObjectType.CONTAINER,
                                item.parent == null ? this.db.get_null () :
                                                      item.parent.id,
                                (int64) item.modified };
        this.db.exec (INSERT_OBJECT_STRING, values);
    }

    private void save_uris (MediaObject obj) throws Error {
        foreach (var uri in obj.uris) {
            GLib.Value[] values = { obj.id, uri };
            db.exec (INSERT_URI_STRING, values);
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
        try {
            db.begin ();
            db.exec (SCHEMA_STRING);
            db.exec (CREATE_TRIGGER_STRING);
            db.commit ();
            return true;
        } catch (Error err) {
            warning ("Failed to create schema: %s", err.message);
            db.rollback ();
        }
        return false;

   }

    private void add_uris (MediaObject obj) throws DatabaseError {
        GLib.Value[] values = { obj.id };
        this.db.exec (URI_GET_STRING,
                                values,
                                (stmt) => {
                                    if (obj is MediaItem)
                                        ((MediaItem) obj).add_uri (stmt.column_text (0), null);
                                    else
                                        obj.uris.add (stmt.column_text (0));
                                });
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
        }

        try {
            if (obj != null) {
                obj.modified = statement.column_int64 (18);
                add_uris (obj);
            }
        } catch (DatabaseError err) {
            warning ("Failed to load uris from database: %s", err.message);
            obj = null;
        }
        return obj;
    }

    public MediaObject? get_object (string object_id) throws DatabaseError {
        MediaObject obj = null;
        GLib.Value[] values  = { object_id };
        Rygel.Database.RowCallback cb = (stmt) => {
            MediaContainer parent = null;
            var parent_id = stmt.column_text (17);
            if (parent_id != null) {
                parent = (MediaContainer) get_object (
                        stmt.column_text (17));
            } else {
                if (stmt.column_text (0) != "0") {
                    warning ("Inconsitent database; non-root element " +
                            "without parent found. Id is %s",
                            stmt.column_text (0));
                }
            }
            obj = get_object_from_statement ((MediaContainer) parent,
                                             object_id,
                                             stmt);
            obj.parent_ref = (MediaContainer) parent;
            obj.parent = obj.parent_ref;
            return false;
        };

        this.db.exec (GET_OBJECT_STRING, values, cb);
        return obj;
    }

    public MediaItem? get_item (string item_id) throws DatabaseError, MediaDBError {
        var obj = get_object (item_id);
        if (obj != null && !(obj is MediaItem))
            throw new MediaDBError.INVALID_TYPE("Object with id %s is not a" +
                                                "MediaItem",
                                                item_id);
        return (MediaItem)obj;
    }

    public MediaContainer? get_container (string container_id)
                                          throws DatabaseError, MediaDBError {
        var obj = get_object (container_id);
        if (obj != null && !(obj is MediaContainer))
            throw new MediaDBError.INVALID_TYPE("Object with id %s is not a" +
                                                "MediaContainer",
                                                container_id);
        return (MediaContainer)obj;
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
                                                         throws DatabaseError {
        ArrayList<string> children = new ArrayList<string> (str_equal);
        GLib.Value[] values = { container_id  };

        this.db.exec (GET_CHILD_ID_STRING,
                      values,
                      (stmt) => {
                                    children.add (stmt.column_text (0));
                        return true;
                      });

        return children;
    }

    public int get_child_count (string container_id) throws DatabaseError {
        int count = 0;
        GLib.Value[] values = { container_id  };

        this.db.exec (CHILDREN_COUNT_STRING,
                      values,
                      (stmt) => {
                          count = stmt.column_int (0);
                          return false;
                      });

        return count;
    }

    public bool exists (string object_id, out int64 timestamp)
                                                          throws DatabaseError {
        bool exists = false;
        GLib.Value[] values = { object_id };
        int64 _timestamp = 0;

        this.db.exec (OBJECT_EXISTS_STRING,
                      values,
                      (stmt) => {
                        exists = stmt.column_int (0) == 1;
                        _timestamp = stmt.column_int64 (1);
                        return false;
                      });
        // out parameters are not allowed to be captured
        timestamp = _timestamp;
        return exists;
    }

    public Gee.ArrayList<MediaObject> get_children (string container_id,
                                                      long offset,
                                                      long max_count) throws
                                                      Error {
        MediaContainer parent = null;
        ArrayList<MediaObject> children = new ArrayList<MediaObject> ();
        parent = (MediaContainer) get_object (container_id);

        GLib.Value[] values = { container_id,
                                (int64) offset,
                                (int64) max_count };
        Rygel.Database.RowCallback cb = (stmt) => {
            var child_id = stmt.column_text (17);
            children.add (get_object_from_statement (parent,
                                                     child_id,
                                                     stmt));
            children[children.size - 1].parent = parent;
            children[children.size - 1].parent_ref = parent;

            return true;
        };

        this.db.exec (GET_CHILDREN_STRING, values, cb);
        return children;
    }
}
