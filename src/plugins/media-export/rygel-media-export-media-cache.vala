/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
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

public errordomain Rygel.MediaExport.MediaCacheError {
    SQLITE_ERROR,
    GENERAL_ERROR,
    INVALID_TYPE,
    UNSUPPORTED_SEARCH
}

internal enum Rygel.MediaExport.ObjectType {
    CONTAINER,
    ITEM
}

internal struct Rygel.MediaExport.ExistsCacheEntry {
    int64 mtime;
    int64 size;
}

/**
 * Persistent storage of media objects
 *
 *  MediaExportDB is a sqlite3 backed persistent storage of media objects
 */
public class Rygel.MediaExport.MediaCache : Object {
    // Private members
    private Database                           db;
    private ObjectFactory                      factory;
    private SQLFactory                         sql;
    private HashMap<string, ExistsCacheEntry?> exists_cache;

    // Private static members
    private static MediaCache instance;

    // Constructors
    private MediaCache () throws Error {
        this.sql = new SQLFactory ();
        this.open_db ("media-export");
        this.factory = new ObjectFactory ();
        this.get_exists_cache ();
    }

    // Public static functions
    public static string get_id (File file) {
        return Checksum.compute_for_string (ChecksumType.MD5,
                                            file.get_uri ());
    }

    public static MediaCache get_default () throws Error {
        if (instance == null) {
            instance = new MediaCache ();
        }

        return instance;
    }

    // Public functions
    public void remove_by_id (string id) throws DatabaseError {
        GLib.Value[] values = { id };
        this.db.exec (this.sql.make (SQLString.DELETE), values);
    }

    public void remove_object (MediaObject object) throws DatabaseError,
                                                          MediaCacheError {
        this.remove_by_id (object.id);
    }

    public void save_container (MediaContainer container) throws Error {
        try {
            db.begin ();
            create_object (container);
            db.commit ();
        } catch (DatabaseError error) {
            db.rollback ();

            throw error;
        }
    }

    public void save_item (Rygel.MediaItem item) throws Error {
        try {
            db.begin ();
            save_metadata (item);
            create_object (item);
            db.commit ();
        } catch (DatabaseError error) {
            warning (_("Failed to add item with ID %s: %s"),
                     item.id,
                     error.message);
            db.rollback ();

            throw error;
        }
    }

    public MediaObject? get_object (string object_id) throws DatabaseError {
        GLib.Value[] values = { object_id };
        MediaObject parent = null;

        var cursor = this.exec_cursor (SQLString.GET_OBJECT, values);

        foreach (var statement in cursor) {
            var parent_container = parent as MediaContainer;
            var object = this.get_object_from_statement
                                        (parent_container,
                                         statement);
            object.parent_ref = parent_container;
            parent = object;
        }

        return parent;
    }

    public MediaContainer? get_container (string container_id)
                                          throws DatabaseError,
                                                 MediaCacheError {
        var object = get_object (container_id);
        if (object != null && !(object is MediaContainer)) {
            throw new MediaCacheError.INVALID_TYPE ("Object with id %s is " +
                                                    "not a MediaContainer",
                                                    container_id);
        }

        return object as MediaContainer;
    }

    public int get_child_count (string container_id) throws DatabaseError {
        GLib.Value[] values = { container_id };

        return this.query_value (SQLString.CHILD_COUNT, values);
    }


    public bool exists (File      file,
                        out int64 timestamp,
                        out int64 size) throws DatabaseError {
        var uri = file.get_uri ();
        GLib.Value[] values = { uri };

        if (this.exists_cache.has_key (uri)) {
            var entry = this.exists_cache.get (uri);
            this.exists_cache.unset (uri);
            timestamp = entry.mtime;
            size = entry.size;

            return true;
        }

        var cursor = this.exec_cursor (SQLString.EXISTS, values);
        var statement = cursor.next ();
        timestamp = statement->column_int64 (1);
        size = statement->column_int64 (2);

        return statement->column_int (0) == 1;
    }

    public MediaObjects get_children (MediaContainer container,
                                      string         sort_criteria,
                                      long           offset,
                                      long           max_count)
                                      throws Error {
        MediaObjects children = new MediaObjects ();

        GLib.Value[] values = { container.id,
                                offset,
                                max_count };

        var sql = this.sql.make (SQLString.GET_CHILDREN);
        var sort_order = this.translate_sort_criteria (sort_criteria);
        var cursor = this.db.exec_cursor (sql.printf (sort_order), values);

        foreach (var statement in cursor) {
            children.add (this.get_object_from_statement (container,
                                                          statement));
            children.last ().parent_ref = container;
        }

        return children;
    }

    public MediaObjects get_objects_by_search_expression
                                        (SearchExpression? expression,
                                         string?           container_id,
                                         string            sort_criteria,
                                         uint              offset,
                                         uint              max_count,
                                         out uint          total_matches)
                                         throws Error {
        var args = new GLib.ValueArray (0);
        var filter = this.translate_search_expression (expression, args);

        if (expression != null) {
            debug ("Original search: %s", expression.to_string ());
            debug ("Parsed search expression: %s", filter);
        }

        var max_objects = modify_limit (max_count);
        total_matches = (uint) get_object_count_by_filter (filter,
                                                           args,
                                                           container_id);

        return this.get_objects_by_filter (filter,
                                           args,
                                           container_id,
                                           sort_criteria,
                                           offset,
                                           max_objects);
    }

    public long get_object_count_by_search_expression
                                        (SearchExpression? expression,
                                         string?           container_id)
                                         throws Error {
        var args = new GLib.ValueArray (0);
        var filter = this.translate_search_expression (expression, args);

        if (expression != null) {
            debug ("Original search: %s", expression.to_string ());
            debug ("Parsed search expression: %s", filter);
        }

        for (int i = 0; i < args.n_values; i++) {
            var arg = args.get_nth (i);
            debug ("Arg %d: %s", i, arg.holds (typeof (string)) ?
                                        arg.get_string () :
                                        arg.strdup_contents ());
        }

        return this.get_object_count_by_filter (filter,
                                                args,
                                                container_id);
    }

    public long get_object_count_by_filter
                                        (string          filter,
                                         GLib.ValueArray args,
                                         string?         container_id)
                                         throws Error {
        if (container_id != null) {
            GLib.Value v = container_id;
            args.prepend (v);
        }

        debug ("Parameters to bind: %u", args.n_values);
        unowned string pattern;
        SQLString string_id;
        if (container_id != null) {
            string_id = SQLString.GET_OBJECT_COUNT_BY_FILTER_WITH_ANCESTOR;
        } else {
            string_id = SQLString.GET_OBJECT_COUNT_BY_FILTER;
        }
        pattern = this.sql.make (string_id);

        return this.db.query_value (pattern.printf (filter), args.values);
    }

    public MediaObjects get_objects_by_filter (string          filter,
                                               GLib.ValueArray args,
                                               string?         container_id,
                                               string          sort_criteria,
                                               long            offset,
                                               long            max_count)
                                               throws Error {
        var children = new MediaObjects ();
        GLib.Value v = offset;
        args.append (v);
        v = max_count;
        args.append (v);
        MediaContainer parent = null;

        debug ("Parameters to bind: %u", args.n_values);
        for (int i = 0; i < args.n_values; i++) {
            var arg = args.get_nth (i);
            debug ("Arg %d: %s", i, arg.holds (typeof (string)) ?
                                        arg.get_string () :
                                        arg.strdup_contents ());
        }

        unowned string sql;
        if (container_id != null) {
            sql = this.sql.make (SQLString.GET_OBJECTS_BY_FILTER_WITH_ANCESTOR);
        } else {
            sql = this.sql.make (SQLString.GET_OBJECTS_BY_FILTER);
        }

        var sort_order = this.translate_sort_criteria (sort_criteria);
        var cursor = this.db.exec_cursor (sql.printf (filter, sort_order),
                                          args.values);
        foreach (var statement in cursor) {
            unowned string parent_id = statement.column_text (DetailColumn.PARENT);

            if (parent == null || parent_id != parent.id) {
                parent = new NullContainer ();
                parent.id = parent_id;
            }

            if (parent != null) {
                children.add (this.get_object_from_statement (parent,
                                                              statement));
                children.last ().parent_ref = parent;
            } else {
                warning ("Inconsistent database: item %s " +
                         "has no parent %s",
                         statement.column_text (DetailColumn.ID),
                         parent_id);
            }
        }

        return children;
    }

    public void debug_statistics () {
        try {
            debug ("Database statistics:");
            var cursor = this.exec_cursor (SQLString.STATISTICS);
            foreach (var statement in cursor) {
                debug ("%s: %d",
                       statement.column_text (0),
                       statement.column_int (1));
            }
        } catch (Error error) { }
    }

    public ArrayList<string> get_child_ids (string container_id)
                                            throws DatabaseError {
        ArrayList<string> children = new ArrayList<string> (str_equal);
        GLib.Value[] values = { container_id  };

        var cursor = this.exec_cursor (SQLString.CHILD_IDS, values);
        foreach (var statement in cursor) {
            children.add (statement.column_text (0));
        }

        return children;
    }

    public Gee.List<string> get_meta_data_column_by_filter
                                        (string          column,
                                         string          filter,
                                         GLib.ValueArray args,
                                         long            offset,
                                         long            max_count)
                                         throws Error {
        GLib.Value v = offset;
        args.append (v);
        v = max_count;
        args.append (v);

        var data = new ArrayList<string> ();

        unowned string sql = this.sql.make (SQLString.GET_META_DATA_COLUMN);
        var cursor = this.db.exec_cursor (sql.printf (column, filter),
                                          args.values);
        foreach (var statement in cursor) {
            data.add (statement.column_text (0));
        }

        return data;
    }

    public Gee.List<string> get_object_attribute_by_search_expression
                                        (string            attribute,
                                         SearchExpression? expression,
                                         long              offset,
                                         uint              max_count)
                                         throws Error {
        var args = new ValueArray (0);
        var filter = this.translate_search_expression (expression,
                                                       args,
                                                       "AND");

        debug ("Parsed filter: %s", filter);

        var column = this.map_operand_to_column (attribute);
        var max_objects = modify_limit (max_count);

        return this.get_meta_data_column_by_filter (column,
                                                    filter,
                                                    args,
                                                    offset,
                                                    max_objects);
    }

    public void flag_object (File file, string flag) throws Error {
        GLib.Value[] args = { flag, file.get_uri () };
        this.db.exec ("UPDATE Object SET flags = ? WHERE uri = ?", args);
    }

    public Gee.List<string> get_flagged_uris (string flag) throws Error {
        var uris = new ArrayList<string> ();
        const string query = "SELECT uri FROM object WHERE flags = ?";

        GLib.Value[] args = { flag };

        var cursor = this.db.exec_cursor (query, args);
        foreach (var statement in cursor) {
            uris.add (statement.column_text (0));
        }

        return uris;
    }

    // Private functions
    private void get_exists_cache () throws DatabaseError {
        this.exists_cache = new HashMap<string, ExistsCacheEntry?> ();
        var cursor = this.exec_cursor (SQLString.EXISTS_CACHE);
        foreach (var statement in cursor) {
            var entry = ExistsCacheEntry ();
            entry.mtime = statement.column_int64 (1);
            entry.size = statement.column_int64 (0);
            this.exists_cache.set (statement.column_text (2), entry);
        }
    }

    private uint modify_limit (uint max_count) {
        if (max_count == 0) {
            return -1;
        } else {
            return max_count;
        }
    }

    private void open_db (string name) throws Error {
        this.db = new Database (name);
        int old_version = -1;
        int current_version = int.parse (SQLFactory.SCHEMA_VERSION);

        try {
            var upgrader = new MediaCacheUpgrader (this.db, this.sql);
            if (upgrader.needs_upgrade (out old_version)) {
                upgrader.upgrade (old_version);
            } else if (old_version == current_version) {
                upgrader.fix_schema ();
            } else {
                warning ("The version \"%d\" of the detected database" +
                         " is newer than our supported version \"%d\"",
                         old_version,
                         current_version);
                this.db = null;

                throw new MediaCacheError.GENERAL_ERROR ("Database format" +
                                                         " not supported");
            }
            upgrader.ensure_indices ();
        } catch (DatabaseError error) {
            debug ("Could not find schema version;" +
                   " checking for empty database...");
            try {
                var rows = this.db.query_value ("SELECT count(type) FROM " +
                                                "sqlite_master WHERE rowid=1");
                if (rows == 0) {
                    debug ("Empty database, creating new schema version %s",
                            SQLFactory.SCHEMA_VERSION);
                    if (!create_schema ()) {
                        this.db = null;

                        return;
                    }
                } else {
                    warning ("Incompatible schema... cannot proceed");
                    this.db = null;

                    return;
                }
            } catch (DatabaseError error) {
                warning ("Something weird going on: %s", error.message);
                this.db = null;

                throw new MediaCacheError.GENERAL_ERROR ("Invalid database");
            }
        }
    }

    private void save_metadata (Rygel.MediaItem item) throws Error {
        // Fill common properties
        GLib.Value[] values = { item.size,
                                item.mime_type,
                                -1,
                                -1,
                                item.upnp_class,
                                Database.null (),
                                Database.null (),
                                item.date,
                                -1,
                                -1,
                                -1,
                                -1,
                                -1,
                                -1,
                                -1,
                                item.id,
                                item.dlna_profile,
                                Database.null (),
                                -1};

        if (item is AudioItem) {
            var audio_item = item as AudioItem;
            values[14] = audio_item.duration;
            values[8] = audio_item.bitrate;
            values[9] = audio_item.sample_freq;
            values[10] = audio_item.bits_per_sample;
            values[11] = audio_item.channels;
            if (item is MusicItem) {
                var music_item = item as MusicItem;
                values[5] = music_item.artist;
                values[6] = music_item.album;
                values[17] = music_item.genre;
                values[12] = music_item.track_number;
                values[18] = music_item.disc;
            }
        }

        if (item is VisualItem) {
            var visual_item = item as VisualItem;
            values[2] = visual_item.width;
            values[3] = visual_item.height;
            values[13] = visual_item.color_depth;
            if (item is VideoItem) {
                var video_item = item as VideoItem;
                values[5] = video_item.author;
            }
        }

        this.db.exec (this.sql.make (SQLString.SAVE_METADATA), values);
    }

    private void create_object (MediaObject item) throws Error {
        int type = ObjectType.CONTAINER;
        GLib.Value parent;

        if (item is MediaItem) {
            type = ObjectType.ITEM;
        }

        if (item.parent == null) {
            parent = Database.@null ();
        } else {
            parent = item.parent.id;
        }

        GLib.Value[] values = { item.id,
                                item.title,
                                type,
                                parent,
                                item.modified,
                                item.uris.size == 0 ? null : item.uris[0]
                              };
        this.db.exec (this.sql.make (SQLString.INSERT), values);
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
            db.exec (this.sql.make (SQLString.SCHEMA));
            db.exec (this.sql.make (SQLString.TRIGGER_COMMON));
            db.exec (this.sql.make (SQLString.TABLE_CLOSURE));
            db.exec (this.sql.make (SQLString.INDEX_COMMON));
            db.exec (this.sql.make (SQLString.TRIGGER_CLOSURE));
            db.commit ();
            db.analyze ();

            return true;
        } catch (Error err) {
            warning ("Failed to create schema: %s", err.message);
            db.rollback ();
        }

        return false;
   }

    private MediaObject? get_object_from_statement (MediaContainer? parent,
                                                    Statement       statement) {
        MediaObject object = null;
        unowned string title = statement.column_text (DetailColumn.TITLE);
        unowned string object_id = statement.column_text (DetailColumn.ID);
        unowned string uri = statement.column_text (DetailColumn.URI);

        switch (statement.column_int (DetailColumn.TYPE)) {
            case 0:
                // this is a container
                object = factory.get_container (this, object_id, title, 0, uri);

                var container = object as MediaContainer;
                if (uri != null) {
                    container.uris.add (uri);
                }
                break;
            case 1:
                // this is an item
                unowned string upnp_class = statement.column_text
                                        (DetailColumn.CLASS);
                object = factory.get_item (this,
                                           parent,
                                           object_id,
                                           title,
                                           upnp_class);
                fill_item (statement, object as MediaItem);

                if (uri != null) {
                    (object as MediaItem).add_uri (uri);
                }
                break;
            default:
                assert_not_reached ();
        }

        if (object != null) {
            object.modified = statement.column_int64 (DetailColumn.TIMESTAMP);
            if (object.modified  == int64.MAX && object is MediaItem) {
                object.modified = 0;
                (object as MediaItem).place_holder = true;
            }
        }

        return object;
    }

    private void fill_item (Statement statement, MediaItem item) {
        // Fill common properties
        item.date = statement.column_text (DetailColumn.DATE);
        item.mime_type = statement.column_text (DetailColumn.MIME_TYPE);
        item.dlna_profile = statement.column_text (DetailColumn.DLNA_PROFILE);
        item.size = statement.column_int64 (DetailColumn.SIZE);

        if (item is AudioItem) {
            var audio_item = item as AudioItem;
            audio_item.duration = (long) statement.column_int64
                                        (DetailColumn.DURATION);
            audio_item.bitrate = statement.column_int (DetailColumn.BITRATE);
            audio_item.sample_freq = statement.column_int
                                        (DetailColumn.SAMPLE_FREQ);
            audio_item.bits_per_sample = statement.column_int
                                        (DetailColumn.BITS_PER_SAMPLE);
            audio_item.channels = statement.column_int (DetailColumn.CHANNELS);
            if (item is MusicItem) {
                var music_item = item as MusicItem;
                music_item.artist = statement.column_text (DetailColumn.AUTHOR);
                music_item.album = statement.column_text (DetailColumn.ALBUM);
                music_item.genre = statement.column_text (DetailColumn.GENRE);
                music_item.track_number = statement.column_int
                                        (DetailColumn.TRACK);
                music_item.lookup_album_art ();
            }
        }

        if (item is VisualItem) {
            var visual_item = item as VisualItem;
            visual_item.width = statement.column_int (DetailColumn.WIDTH);
            visual_item.height = statement.column_int (DetailColumn.HEIGHT);
            visual_item.color_depth = statement.column_int
                                        (DetailColumn.COLOR_DEPTH);
            if (item is VideoItem) {
                var video_item = item as VideoItem;
                video_item.author = statement.column_text (DetailColumn.AUTHOR);
            }
        }
    }

    private string translate_search_expression
                                        (SearchExpression? expression,
                                         ValueArray        args,
                                         string            prefix = "WHERE")
                                         throws Error {
        if (expression == null) {
            return "";
        }

        var filter = this.search_expression_to_sql (expression, args);

        return " %s %s".printf (prefix, filter);
    }

    private string? search_expression_to_sql (SearchExpression? expression,
                                             GLib.ValueArray   args)
                                             throws Error {
        if (expression == null) {
            return "";
        }

        if (expression is LogicalExpression) {
            return this.logical_expression_to_sql
                                        (expression as LogicalExpression, args);
        } else {
            return this.relational_expression_to_sql
                                        (expression as RelationalExpression,
                                         args);
        }
    }

    private string? logical_expression_to_sql (LogicalExpression? expression,
                                               GLib.ValueArray    args)
                                               throws Error {
        string left_sql_string = search_expression_to_sql (expression.operand1,
                                                           args);
        string right_sql_string = search_expression_to_sql (expression.operand2,
                                                            args);
        string operator_sql_string = "OR";

        if (expression.op == LogicalOperator.AND) {
            operator_sql_string = "AND";
        }

        return "(%s %s %s)".printf (left_sql_string,
                                    operator_sql_string,
                                    right_sql_string);
    }

    private string? map_operand_to_column (string     operand,
                                           out string? collate = null)
                                           throws Error {
        string column = null;
        bool use_collation = false;

        switch (operand) {
            case "res":
                column = "o.uri";
                break;
            case "res@duration":
                column = "m.duration";
                break;
            case "@refID":
                column = "NULL";
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
                use_collation = true;
                break;
            case "upnp:artist":
            case "dc:creator":
                column = "m.author";
                use_collation = true;
                break;
            case "dc:date":
                column = "strftime(\"%Y\", m.date)";
                break;
            case "upnp:album":
                column = "m.album";
                use_collation = true;
                break;
            case "upnp:genre":
            case "dc:genre":
                // FIXME: Remove dc:genre, upnp:genre is the correct one
                column = "m.genre";
                use_collation = true;
                break;
            case "upnp:originalTrackNumber":
                column = "m.track";
                break;
            case "rygel:originalVolumeNumber":
                column = "m.disc";
                break;
            default:
                var message = "Unsupported column %s".printf (operand);

                throw new MediaCacheError.UNSUPPORTED_SEARCH (message);
        }

        if (use_collation) {
            collate = "COLLATE CASEFOLD";
        } else {
            collate = "";
        }

        return column;
    }

    private string? relational_expression_to_sql (RelationalExpression? exp,
                                                  GLib.ValueArray       args)
                                                  throws Error {
        GLib.Value? v = null;
        string collate = null;

        string column = map_operand_to_column (exp.operand1, out collate);
        SqlOperator operator;

        switch (exp.op) {
            case SearchCriteriaOp.EXISTS:
                string sql_function;
                if (exp.operand2 == "true") {
                    sql_function = "%s IS NOT NULL AND %s != ''";
                } else {
                    sql_function = "%s IS NULL OR %s = ''";
                }

                return sql_function.printf (column, column);
            case SearchCriteriaOp.EQ:
            case SearchCriteriaOp.NEQ:
            case SearchCriteriaOp.LESS:
            case SearchCriteriaOp.LEQ:
            case SearchCriteriaOp.GREATER:
            case SearchCriteriaOp.GEQ:
                v = exp.operand2;
                operator = new SqlOperator.from_search_criteria_op
                                        (exp.op, column, collate);
                break;
            case SearchCriteriaOp.CONTAINS:
                operator = new SqlFunction ("contains", column);
                v = exp.operand2;
                break;
            case SearchCriteriaOp.DOES_NOT_CONTAIN:
                operator = new SqlFunction ("NOT contains", column);
                v = exp.operand2;
                break;
            case SearchCriteriaOp.DERIVED_FROM:
                operator = new SqlOperator ("LIKE", column);
                v = "%s%%".printf (exp.operand2);
                break;
            default:
                warning ("Unsupported op %d", exp.op);
                return null;
        }

        if (v != null) {
            args.append (v);
        }

        return operator.to_string ();
    }

    private DatabaseCursor exec_cursor (SQLString      id,
                                        GLib.Value[]?  values = null)
                                        throws DatabaseError {
        return this.db.exec_cursor (this.sql.make (id), values);
    }

    private int query_value (SQLString      id,
                             GLib.Value[]?  values = null)
                             throws DatabaseError {
        return this.db.query_value (this.sql.make (id), values);
    }

    private string translate_sort_criteria (string sort_criteria) {
        string? collate;
        var builder = new StringBuilder("ORDER BY ");
        var fields = sort_criteria.split (",");
        foreach (var field in fields) {
            try {
                var column = this.map_operand_to_column (field[1:field.length],
                                                         out collate);
                if (field != fields[0]) {
                    builder.append (",");
                }
                builder.append_printf ("%s %s %s ",
                                       column,
                                       collate,
                                       field[0] == '-' ? "DESC" : "ASC");
            } catch (Error error) {
                warning ("Skipping nsupported field: %s", field);
            }
        }

        return builder.str;
    }
}
