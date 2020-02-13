/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>,
 *           (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

using Rygel;
using Rygel.Database;
using Gee;
using Sqlite;

public errordomain Rygel.LMS.CategoryContainerError {
    SQLITE_ERROR,
    GENERAL_ERROR,
    INVALID_TYPE,
    UNSUPPORTED_SEARCH
}

public abstract class Rygel.LMS.CategoryContainer : Rygel.MediaContainer,
                                                    Rygel.TrackableContainer,
                                                    Rygel.SearchableContainer {
    public ArrayList<string> search_classes { get; set; }

    public unowned LMS.Database lms_db { get; construct; }

    public string db_id { get; construct; }

    public string sql_all { get; construct; }
    public string sql_find_object { get; construct; }
    public string sql_count { get; construct; }
    public string sql_added { get; construct; }
    public string sql_removed { get; construct; }

    protected Cursor cursor_all;
    protected Cursor cursor_find_object;
    protected Cursor cursor_added;
    protected Cursor cursor_removed;

    protected string child_prefix;
    protected string ref_prefix;

    protected abstract MediaObject? object_from_statement (Statement statement);

    /* TODO these should be abstract */
    protected virtual string get_sql_all_with_filter (string filter) {
        return this.sql_all;
    }
    protected virtual string get_sql_count_with_filter (string filter) {
        return this.sql_count;
    }

    private static string? map_operand_to_column (string     operand,
                                                  out string? collate = null,
                                                  bool        for_sort = false)
                                                  throws Error {
        string column = null;
        bool use_collation = false;

        // TODO add all used aliases to sql queries
        switch (operand) {
            case "dc:title":
                column = "title";
                use_collation = true;
                break;
            case "upnp:artist":
                column = "artist";
                use_collation = true;
                break;
            case "dc:creator":
                column = "creator";
                use_collation = true;
                break;
            default:
                var message = "Unsupported column %s".printf (operand);

                throw new CategoryContainerError.UNSUPPORTED_SEARCH (message);
        }

        if (use_collation) {
            collate = "COLLATE CASEFOLD";
        } else {
            collate = "";
        }

        return column;
    }

    private static string? relational_expression_to_sql
                                        (RelationalExpression exp,
                                         GLib.ValueArray      args)
                                         throws Error {
        GLib.Value? v = null;
        string collate = null;

        string column = CategoryContainer.map_operand_to_column (exp.operand1,
                                                                 out collate);
        SqlOperator operator;

        switch (exp.op) {
            case GUPnP.SearchCriteriaOp.EXISTS:
                string sql_function;
                if (exp.operand2 == "true") {
                    sql_function = "%s IS NOT NULL AND %s != ''";
                } else {
                    sql_function = "%s IS NULL OR %s = ''";
                }

                return sql_function.printf (column, column);
            case GUPnP.SearchCriteriaOp.EQ:
            case GUPnP.SearchCriteriaOp.NEQ:
            case GUPnP.SearchCriteriaOp.LESS:
            case GUPnP.SearchCriteriaOp.LEQ:
            case GUPnP.SearchCriteriaOp.GREATER:
            case GUPnP.SearchCriteriaOp.GEQ:
                v = exp.operand2;
                operator = new SqlOperator.from_search_criteria_op
                                            (exp.op, column, collate);
                break;
            case GUPnP.SearchCriteriaOp.CONTAINS:
                operator = new SqlFunction ("contains", column);
                v = exp.operand2;
                break;
            case GUPnP.SearchCriteriaOp.DOES_NOT_CONTAIN:
                operator = new SqlFunction ("NOT contains", column);
                v = exp.operand2;
                break;
            case GUPnP.SearchCriteriaOp.DERIVED_FROM:
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

    private static string logical_expression_to_sql
                                        (LogicalExpression expression,
                                         GLib.ValueArray   args)
                                         throws Error {
        string left_sql_string = CategoryContainer.search_expression_to_sql
                                        (expression.operand1,
                                         args);
        string right_sql_string = CategoryContainer.search_expression_to_sql
                                        (expression.operand2,
                                         args);
        unowned string operator_sql_string = "OR";

        if (expression.op == LogicalOperator.AND) {
            operator_sql_string = "AND";
        }

        return "(%s %s %s)".printf (left_sql_string,
                                    operator_sql_string,
                                    right_sql_string);
    }

    private static string? search_expression_to_sql
                                        (SearchExpression? expression,
                                         GLib.ValueArray   args)
                                         throws Error {
        if (expression == null) {
            return "";
        }

        if (expression is LogicalExpression) {
            return CategoryContainer.logical_expression_to_sql
                                        ((LogicalExpression) expression, args);
        } else {
            return CategoryContainer.relational_expression_to_sql
                                        ((RelationalExpression) expression,
                                         args);
        }
    }

    protected virtual uint get_child_count_with_filter (string     where_filter,
                                                        ValueArray args)
    {
        var query = this.get_sql_count_with_filter (where_filter);
        try {
            return this.lms_db.query_value (query, args.values);
        } catch (DatabaseError e) {
            warning ("Query failed: %s", e.message);

            return 0;
        }
    }

    protected virtual MediaObjects? get_children_with_filter
                                        (string     where_filter,
                                         ValueArray args,
                                         string     sort_criteria,
                                         uint       offset,
                                         uint       max_count) {
        var children = new MediaObjects ();
        GLib.Value v = max_count;
        args.append (v);
        v = offset;
        args.append (v);

        var query = this.get_sql_all_with_filter (where_filter);
        try {
            var cursor = this.lms_db.exec_cursor (query, args.values);
            foreach (var stmt in cursor) {
                children.add (this.object_from_statement (stmt));
            }
        } catch (DatabaseError e) {
            warning ("Query failed: %s", e.message);
        }

        return children;
    }

    public async MediaObjects? search (SearchExpression? expression,
                                       uint offset,
                                       uint max_count,
                                       string sort_criteria,
                                       Cancellable? cancellable,
                                       out uint total_matches)
                                        throws Error {
        debug ("search()");
        try {
            var args = new GLib.ValueArray (0);
            var filter = CategoryContainer.search_expression_to_sql (expression,
                                                                     args);
            total_matches = this.get_child_count_with_filter (filter, args);

            if (expression != null) {
                debug ("  Original search: %s", expression.to_string ());
                debug ("  Parsed search expression: %s", filter);
                debug ("  Filtered cild count is %u", total_matches);
            }

            if (max_count == 0) {
                max_count = uint.MAX;
            }

            return this.get_children_with_filter (filter,
                                                  args,
                                                  sort_criteria,
                                                  offset,
                                                  max_count);
        } catch (Error e) {
            debug ("  Falling back to simple_search(): %s", e.message);

            return yield this.simple_search (expression,
                                             offset,
                                             max_count,
                                             sort_criteria,
                                             cancellable,
                                             out total_matches);
        }
    }

    public async override MediaObjects? get_children (uint offset,
                                                      uint max_count,
                                                      string sort_criteria,
                                                      Cancellable? cancellable)
                                        throws Error {
        MediaObjects retval = new MediaObjects ();

        // FIXME: sort_criteria is ignored
        GLib.Value[] args = { max_count, offset };

        this.cursor_all.bind (args);
        foreach (var stmt in cursor_all) {
            retval.add (this.object_from_statement (stmt));
        }

        return retval;
    }

    public async override MediaObject? find_object (string id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        if (!id.has_prefix (this.child_prefix)) {
            /* can't match anything in this container */
            return null;
        }

        MediaObject object = null;

        /* remove parent section from id */
        var real_id = id.substring (this.child_prefix.length);
        /* remove grandchildren from id */
        var index = real_id.index_of_char (':');
        if (index > 0) {
            real_id = real_id.slice (0, index);
        }

        try {
            GLib.Value[] args = { int.parse (real_id) };
            this.cursor_find_object.bind (args);
            foreach (var statement in this.cursor_find_object) {
                var child = this.object_from_statement (statement);
                if (index < 0) {
                    object = child;
                } else {
                    /* try grandchildren */
                    var container = (CategoryContainer) child;
                    object = yield container.find_object (id, cancellable);

                    /* tell object to keep a reference to the parent --
                     * otherwise parent is freed before object is serialized */
                    object.parent_ref = object.parent;
                }
            }
        } catch (DatabaseError e) {
            debug ("find_object %s in %s: %s", id, this.id, e.message);
            /* Happens e.g. if id is not an integer */
        }

        return object;
    }

    protected string build_child_id (int db_id) {
        return "%s%d".printf (this.child_prefix, db_id);
    }

    protected string build_reference_id (int db_id) {
        return "%s%d".printf (this.ref_prefix, db_id);
    }

    protected async void add_child (MediaObject object) {
    }

    protected async void remove_child (MediaObject object) {
    }

    private void on_db_updated(uint64 old_id, uint64 new_id) {
        try {
            this.child_count = this.lms_db.query_value (this.sql_count);

            GLib.Value[] args = { new_id < old_id ? 0 : old_id,
                                  new_id };
            this.cursor_added.bind (args);
            foreach (var stmt in this.cursor_added) {
                var object = this.object_from_statement (stmt);
                this.add_child_tracked.begin (object);
            }

            this.cursor_removed.bind (args);
            foreach (var stmt in this.cursor_removed) {
                var object = this.object_from_statement (stmt);
                this.remove_child_tracked.begin (object);
            }

        } catch (DatabaseError e) {
            warning ("Can't perform container update: %s", e.message);
        }

    }

    protected CategoryContainer (string db_id,
                                 MediaContainer parent,
                                 string title,
                                 LMS.Database lms_db,
                                 string sql_all,
                                 string sql_find_object,
                                 string sql_count,
                                 string? sql_added,
                                 string? sql_removed
                                ) {
        Object (id : "%s:%s".printf (parent.id, db_id),
                db_id : db_id,
                parent : parent,
                title : title,
                lms_db : lms_db,
                sql_all : sql_all,
                sql_find_object : sql_find_object,
                sql_count : sql_count,
                sql_added : sql_added,
                sql_removed: sql_removed
               );
    }

    construct {
        this.search_classes = new ArrayList<string> ();

        this.child_prefix = "%s:".printf (this.id);

        var index = this.id.index_of_char (':');
        this.ref_prefix = this.id.slice (0, index) + ":all:";

        try {
            this.cursor_all = this.lms_db.exec_cursor (this.sql_all);
            this.cursor_find_object = this.lms_db.exec_cursor
                                        (this.sql_find_object);

            this.child_count = this.lms_db.query_value (this.sql_count);
            // some container implementations don't have a reasonable way to provide
            // id-based statements to fetch added or removed items
            if (this.sql_added != null && this.sql_removed != null) {
                this.cursor_added = this.lms_db.exec_cursor (this.sql_added);
                this.cursor_removed = this.lms_db.exec_cursor (this.sql_removed);
                lms_db.db_updated.connect (this.on_db_updated);
            }
        } catch (DatabaseError e) {
            warning ("Container %s: %s", this.title, e.message);
        }

    }
}
