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
using GUPnP;
using Sqlite;

public errordomain Rygel.MediaDBError {
    SQLITE_ERROR,
    GENERAL_ERROR,
    INVALID_TYPE,
    UNSUPPORTED
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
    private Rygel.Database db;
    private MediaDBObjectFactory factory;
    private const string schema_version = "5";
    private const string SCHEMA_STRING =
    "CREATE TABLE schema_info (version TEXT NOT NULL); " +
    "CREATE TABLE object_type (id INTEGER PRIMARY KEY, " +
                              "desc TEXT NOT NULL);" +
    "CREATE TABLE meta_data (size INTEGER NOT NULL, " +
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
    "CREATE TABLE object (parent TEXT CONSTRAINT parent_fk_id " +
                                "REFERENCES Object(upnp_id), " +
                          "upnp_id TEXT PRIMARY KEY, " +
                          "type_fk INTEGER CONSTRAINT type_fk_id " +
                                "REFERENCES Object_Type(id), " +
                          "title TEXT NOT NULL, " +
                          "timestamp INTEGER NOT NULL);" +
    "CREATE TABLE uri (object_fk TEXT " +
                        "CONSTRAINT object_fk_id REFERENCES Object(upnp_id) "+
                            "ON DELETE CASCADE, " +
                      "uri TEXT NOT NULL);" +
    "INSERT INTO object_type (id, desc) VALUES (0, 'Container'); " +
    "INSERT INTO object_type (id, desc) VALUES (1, 'Item'); " +
    "INSERT INTO schema_info (version) VALUES ('" + MediaDB.schema_version +
                                                "'); ";

    private const string CREATE_CLOSURE_TABLE =
    "CREATE TABLE closure (ancestor TEXT, descendant TEXT, depth INTEGER)";

    private const string CREATE_CLOSURE_TRIGGER_STRING =
    "CREATE TRIGGER trgr_update_closure " +
    "AFTER INSERT ON Object " +
    "FOR EACH ROW BEGIN " +
        "INSERT INTO Closure (ancestor, descendant, depth) " +
            "VALUES (NEW.upnp_id, NEW.upnp_id, 0); " +
        "INSERT INTO Closure (ancestor, descendant, depth) " +
            "SELECT ancestor, NEW.upnp_id, depth + 1 FROM Closure " +
                "WHERE descendant = NEW.parent;" +
    "END;" +

    "CREATE TRIGGER trgr_delete_closure " +
    "AFTER DELETE ON Object " +
    "FOR EACH ROW BEGIN " +
        "DELETE FROM Closure WHERE descendant = OLD.upnp_id;" +
    "END;";

    private const string CREATE_TRIGGER_STRING =
    "CREATE TRIGGER trgr_delete_metadata " +
    "BEFORE DELETE ON Object " +
    "FOR EACH ROW BEGIN " +
        "DELETE FROM meta_data WHERE meta_data.object_fk = OLD.upnp_id; "+
    "END;" +

    "CREATE TRIGGER trgr_delete_uris " +
    "BEFORE DELETE ON Object " +
    "FOR EACH ROW BEGIN " +
        "DELETE FROM Uri WHERE Uri.object_fk = OLD.upnp_id;" +
    "END;";

    private const string CREATE_INDICES_STRING =
    "CREATE INDEX idx_parent on Object(parent);" +
    "CREATE INDEX idx_uri_fk on Uri(object_fk);" +
    "CREATE INDEX idx_meta_data_fk on meta_data(object_fk);" +
    "CREATE INDEX idx_closure on Closure(descendant,depth);";

    private const string SAVE_META_DATA_STRING =
    "INSERT OR REPLACE INTO meta_data " +
        "(size, mime_type, width, height, class, " +
         "author, album, date, bitrate, " +
         "sample_freq, bits_per_sample, channels, " +
         "track, color_depth, duration, object_fk) VALUES " +
         "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

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
    "DELETE FROM Object WHERE upnp_id = " +
        "(SELECT descendant FROM closure WHERE ancestor = ?)";

    private const string GET_OBJECT_WITH_CLOSURE =
    "SELECT o.type_fk, o.title, m.size, m.mime_type, m.width, m.height, " +
            "m.class, m.author, m.album, m.date, m.bitrate, m.sample_freq, " +
            "m.bits_per_sample, m.channels, m.track, m.color_depth, " +
            "m.duration, o.parent, o.upnp_id " +
    "FROM Object o " +
        "JOIN Closure c ON (o.upnp_id = c.ancestor) " +
        "LEFT OUTER JOIN meta_data m ON (o.upnp_id = m.object_fk) " +
            "WHERE c.descendant = ? ORDER BY c.depth DESC";

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
    "SELECT o.type_fk, o.title, m.size, m.mime_type, " +
            "m.width, m.height, m.class, m.author, m.album, " +
            "m.date, m.bitrate, m.sample_freq, m.bits_per_sample, " +
            "m.channels, m.track, m.color_depth, m.duration, " +
            "o.upnp_id, o.parent, o.timestamp " +
    "FROM Object o LEFT OUTER JOIN meta_data m " +
        "ON o.upnp_id = m.object_fk " +
    "WHERE o.parent = ? " +
        "ORDER BY o.type_fk ASC, " +
                 "m.class ASC, " +
                 "m.track ASC, " +
                 "o.title ASC " +
    "LIMIT ?,?";

    private const string GET_OBJECTS_STRING_WITH_FILTER =
    "SELECT DISTINCT o.type_fk, o.title, m.size, m.mime_type, " +
            "m.width, m.height, m.class, m.author, m.album, " +
            "m.date, m.bitrate, m.sample_freq, m.bits_per_sample, " +
            "m.channels, m.track, m.color_depth, m.duration, " +
            "o.upnp_id, o.parent, o.timestamp " +
    "FROM Object o " +
        "JOIN Closure c ON o.upnp_id = c.descendant AND c.ancestor = ? " +
        "LEFT OUTER JOIN meta_data m " +
            "ON o.upnp_id = m.object_fk " +
        "LEFT OUTER JOIN Uri u ON u.object_fk = o.upnp_id " +
    "WHERE %s " +
        "ORDER BY o.type_fk ASC, " +
                 "m.class ASC, " +
                 "m.track ASC, " +
                 "o.title ASC " +
    "LIMIT ?,?";


    private const string URI_GET_STRING =
    "SELECT uri FROM Uri WHERE Uri.object_fk = ?";

    private const string CHILDREN_COUNT_STRING =
    "SELECT COUNT(upnp_id) FROM Object WHERE Object.parent = ?";

    private const string OBJECT_EXISTS_STRING =
    "SELECT COUNT(upnp_id), timestamp FROM Object WHERE Object.upnp_id = ?";

    private const string OBJECT_DELETE_STRING =
    "DELETE FROM Object WHERE Object.upnp_id = ?";

    private const string GET_CHILD_ID_STRING =
    "SELECT upnp_id FROM OBJECT WHERE parent = ?";

    private const string UPDATE_V3_V4_STRING_1 =
    "ALTER TABLE meta_data ADD object_fk TEXT";

    private const string UPDATE_V3_V4_STRING_2 =
    "UPDATE meta_data SET object_fk = " +
        "(SELECT upnp_id FROM Object WHERE metadata_fk = meta_data.id)";

    private const string UPDATE_V3_V4_STRING_3 =
    "ALTER TABLE Object ADD timestamp INTEGER";

    private const string UPDATE_V3_V4_STRING_4 =
    "UPDATE Object SET timestamp = 0";

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
    }


    public void remove_object (MediaObject obj) throws DatabaseError,
                                                       MediaDBError {
        this.remove_by_id (obj.id);
        if (obj is MediaItem) {
            item_removed (obj.id);
        } else if (obj is MediaContainer) {
            container_removed (obj.id);
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
                save_metadata ((MediaItem) obj);
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

    public MediaObject? get_object (string object_id) throws DatabaseError {
        GLib.Value[] values = { object_id };
        MediaObject parent = null;
        Rygel.Database.RowCallback cb = (stmt) => {
            var obj = get_object_from_statement ((MediaContainer) parent,
                                                 stmt.column_text (18),
                                                 stmt);
            obj.parent = (MediaContainer) parent;
            obj.parent_ref = (MediaContainer) parent;
            parent = obj;
            return true;
        };

        this.db.exec (GET_OBJECT_WITH_CLOSURE, values, cb);
        return parent;
    }

    public MediaItem? get_item (string item_id)
                                throws DatabaseError, MediaDBError {
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
        return (MediaContainer) obj;
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

    public bool exists (string    object_id,
                        out int64 timestamp) throws DatabaseError {
        bool exists = false;
        GLib.Value[] values = { object_id };
        int64 tmp_timestamp = 0;

        this.db.exec (OBJECT_EXISTS_STRING,
                      values,
                      (stmt) => {
                        exists = stmt.column_int (0) == 1;
                        tmp_timestamp = stmt.column_int64 (1);
                        return false;
                      });

        // out parameters are not allowed to be captured
        timestamp = tmp_timestamp;
        return exists;
    }

    public Gee.ArrayList<MediaObject> get_children (string container_id,
                                                    long offset,
                                                    long max_count)
                                                    throws Error {
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

    public Gee.List<MediaObject> get_objects_by_search_expression (
                                        SearchExpression expression,
                                        string           container_id,
                                        uint             offset,
                                        uint             max_count)
                                        throws Error {
        var args = new GLib.ValueArray(0);
        var filter = this.search_expression_to_sql (expression, args);

        if (filter == null) {
            return new Gee.ArrayList<MediaObject> ();
        }

        debug ("Orignal search: %s", expression.to_string ());
        debug ("Parsed search expression: %s", filter);

        for (int i = 0; i < args.n_values; i++) {
            debug ("Arg %d: %s", i, args.get_nth (i).get_string ());
        }

         var max_objects = max_count;
         if (max_objects == 0) {
             max_objects = -1;
         }

        return this.get_objects_by_filter (filter,
                                           args,
                                           container_id,
                                           offset,
                                           max_objects);
    }

    public Gee.ArrayList<MediaObject> get_objects_by_filter (
                                        string          filter,
                                        GLib.ValueArray args,
                                        string          container_id,
                                        long            offset,
                                        long            max_count)
                                        throws Error {
        ArrayList<MediaObject> children = new ArrayList<MediaObject> ();
        GLib.Value v = container_id;
        args.prepend (v);
        v = offset;
        args.append (v);
        v = max_count;
        args.append (v);

        debug ("Parameters to bind: %u", args.n_values);

        Rygel.Database.RowCallback cb = (stmt) => {
            var child_id = stmt.column_text (17);
            var parent_id = stmt.column_text (18);
            try {
                var parent = (MediaContainer) get_object (parent_id);
                children.add (get_object_from_statement (parent,
                            child_id,
                            stmt));
                children[children.size - 1].parent = parent;
                children[children.size - 1].parent_ref = parent;

                return true;
            } catch (DatabaseError e) {
                warning ("Failed to get parent item: %s", e.message);
                return false;
            }
        };

        this.db.exec (GET_OBJECTS_STRING_WITH_FILTER.printf (filter),
                      args.values,
                      cb);
        return children;
    }

    public MediaDB (string name) throws Error {
        open_db (name);
        this.factory = new MediaDBObjectFactory ();
    }

    public MediaDB.with_factory (string               name,
                                 MediaDBObjectFactory factory) throws Error {
        this.open_db (name);
        this.factory = factory;
    }

    private void open_db (string name) throws Error {
        this.db = new Rygel.Database (name);
        int old_version = -1;

        try {
            this.db.exec ("SELECT version FROM schema_info",
                          null,
                          (stmt) => {
                              old_version = stmt.column_int (0);
                              return false;
                          });
            int current_version = schema_version.to_int();
            if (old_version == current_version) {
                debug ("Media DB schema has current version");
            } else {
                if (old_version < current_version) {
                    debug ("Older schema detected. Upgrading...");
                    switch (old_version) {
                        case 3:
                            update_v3_v4 ();
                            break;
                        case 4:
                            update_v4_v5 ();
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
                    this.db = null;
                    throw new MediaDBError.GENERAL_ERROR("Database format" +
                            " not supported");
                }
            }
        } catch (DatabaseError err) {
            debug ("Could not find schema version;" +
                   " checking for empty database...");
            try {
                int rows = -1;
                this.db.exec ("SELECT count(type) FROM sqlite_master " +
                              "WHERE rowid=1",
                              null,
                              (stmt) => {
                                  rows = stmt.column_int (0);

                                  return false;
                              });
                if (rows == 0) {
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
            } catch (DatabaseError err2) {
                warning ("Something weird going on: %s", err2.message);
                this.db = null;
                throw new MediaDBError.GENERAL_ERROR("Invalid database");
            }
        }
    }

    private void update_v3_v4 () {
        try {
            db.begin ();
            db.exec (UPDATE_V3_V4_STRING_1);
            db.exec (UPDATE_V3_V4_STRING_2);
            db.exec (UPDATE_V3_V4_STRING_3);
            db.exec (UPDATE_V3_V4_STRING_4);
            db.exec (CREATE_TRIGGER_STRING);
            db.exec ("UPDATE schema_info SET version = '4'");
            db.commit ();
        } catch (DatabaseError err) {
            db.rollback ();
            warning ("Database upgrade failed: %s", err.message);
            db = null;
        }
    }

    private void update_v4_v5 () {
        try {
            db.begin ();
            db.exec ("DROP TRIGGER IF EXISTS trgr_delete_children");
            db.exec (CREATE_CLOSURE_TABLE);
            // this is to have the database generate the closure table
            db.exec ("ALTER TABLE Object RENAME TO _Object");
            db.exec ("CREATE TABLE Object AS SELECT * FROM _Object");
            db.exec ("DELETE FROM Object");
            db.exec (CREATE_CLOSURE_TRIGGER_STRING);
            db.exec ("INSERT INTO Object SELECT * FROM _Object");
            db.exec ("DROP TABLE Object");
            db.exec ("ALTER TABLE _Object RENAME TO Object");
            // the triggers created above have been dropped automatically
            // so we need to recreate them
            db.exec (CREATE_CLOSURE_TRIGGER_STRING);
            db.exec (CREATE_INDICES_STRING);
            db.exec ("UPDATE schema_info SET version = '5'");
            db.commit ();
            db.exec ("VACUUM");
            db.analyze ();
        } catch (DatabaseError err) {
            db.rollback ();
            warning ("Database upgrade failed: %s", err.message);
            db = null;
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

    private void save_metadata (MediaItem item) throws Error {
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
        this.db.exec (SAVE_META_DATA_STRING, values);
    }

    private void create_object (MediaObject item) throws Error {
        GLib.Value[] values = { item.id,
                                item.title,
                                (item is MediaItem)
                                           ? (int) MediaDBObjectType.ITEM
                                           : (int) MediaDBObjectType.CONTAINER,
                                item.parent == null ? Database.null () :
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
            db.exec (CREATE_CLOSURE_TABLE);
            db.exec (CREATE_INDICES_STRING);
            db.exec (CREATE_CLOSURE_TRIGGER_STRING);
            db.commit ();
            db.analyze ();
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
                          if (obj is MediaItem) {
                              var item = obj as MediaItem;
                              item.add_uri (stmt.column_text (0), null);
                          } else {
                              obj.uris.add (stmt.column_text (0));
                          }

                          return true;
                      });
    }

    private MediaObject? get_object_from_statement (MediaContainer? parent,
                                                    string          object_id,
                                                    Statement       statement) {
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

    private string? search_expression_to_sql (SearchExpression? expression,
                                             GLib.ValueArray   args)
                                             throws Error {
        if (expression == null) {
            return null;
        }

        if (expression is LogicalExpression) {
            return logexp_to_sql (expression as LogicalExpression, args);
        } else {
            return relexp_to_sql (expression as RelationalExpression, args);
        }
    }

    private string? logexp_to_sql (LogicalExpression? exp,
                                   GLib.ValueArray    args) throws Error {
        string left = search_expression_to_sql (exp.operand1, args);
        string right = search_expression_to_sql (exp.operand2, args);
        string op;
        if (exp.op == LogicalOperator.AND) {
            op = "AND";
        } else {
            op = "OR";
        }

        return "(%s %s %s)".printf (left, op, right);
    }

    private string? map_operand_to_column (string operand) throws Error {
        string column = null;

        switch (operand) {
            case "res":
                column = "u.uri";
                break;
            case "@id":
                column = "o.upnp_id";
                break;
            case "@parentID":
                column = "o.parent";
                break;
            case "upnp:class":
                column = "m.class";
                break;
            case "dc:title":
                column = "o.title";
                break;
            case "upnp:artist":
            case "dc:creator":
                column = "m.author";
                break;
            case "dc:date":
                column = "m.date";
                break;
            case "upnp:album":
                column = "m.album";
                break;
            default:
                var msg = "Unsupported column %s".printf (operand);
                throw new MediaDBError.UNSUPPORTED (msg);
        }

        return column;
    }

    private string? relexp_to_sql (RelationalExpression? exp,
                                   GLib.ValueArray       args) throws Error {
        string func = null;
        GLib.Value? v = null;

        string column = map_operand_to_column (exp.operand1);

        switch (exp.op) {
            case SearchCriteriaOp.EXISTS:
                if (exp.operand2 == "true")
                    func = "IS NOT NULL AND %s != ''";
                else
                    func = "IS NULL OR %s = ''";
                break;
            case SearchCriteriaOp.EQ:
                func = "=";
                v = exp.operand2;
                break;
            case SearchCriteriaOp.NEQ:
                func = "!=";
                v = exp.operand2;
                break;
            case SearchCriteriaOp.LESS:
                func = "<";
                v = exp.operand2;
                break;
            case SearchCriteriaOp.LEQ:
                func = "<=";
                v = exp.operand2;
                break;
            case SearchCriteriaOp.GREATER:
                func = ">";
                v = exp.operand2;
                break;
            case SearchCriteriaOp.GEQ:
                func = ">=";
                v = exp.operand2;
                break;
            case SearchCriteriaOp.CONTAINS:
                func = "LIKE";
                v = "%%%s%%".printf (exp.operand2);
                break;
            case SearchCriteriaOp.DOES_NOT_CONTAIN:
                func = "NOT LIKE";
                v = "%%%s%%".printf (exp.operand2);
                break;
            case SearchCriteriaOp.DERIVED_FROM:
                func = "LIKE";
                v = "%s%%".printf (exp.operand2);
                break;
            default:
                warning ("Unsupported op %d", exp.op);
                break;
        }

        if (v != null) {
            args.append (v);
        }

        return "%s %s ?".printf (column, func);
    }

}
