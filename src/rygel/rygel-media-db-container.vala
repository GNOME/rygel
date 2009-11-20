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
using GUPnP;

public class Rygel.MediaDBContainer : MediaContainer {
    protected MediaDB media_db;

    public MediaDBContainer (MediaDB media_db, string id, string title) {
        int count;
        try {
            count = media_db.get_child_count (id);
        } catch (DatabaseError e) {
            debug("Could not get child count from database: %s",
                  e.message);
            count = 0;
        }
        base (id, null, title, count);

        this.media_db = media_db;
        this.container_updated.connect (on_db_container_updated);
    }

    private void on_db_container_updated (MediaContainer container,
                                          MediaContainer container_updated) {
        try {
            this.child_count = media_db.get_child_count (this.id);
        } catch (DatabaseError e) {
            debug("Could not get child count from database: %s",
                  e.message);
            this.child_count = 0;
        }
    }

    public override async Gee.List<MediaObject>? get_children (
                                        uint               offset,
                                        uint               max_count,
                                        Cancellable?       cancellable)
                                        throws GLib.Error {
        var children = this.media_db.get_children (this.id,
                                                   offset,
                                                   max_count);
        foreach (var child in children) {
            child.parent = this;
        }

        return children;
    }

    public override async Gee.List<MediaObject>? search (
                                        SearchExpression expression,
                                        uint             offset,
                                        uint             max_count,
                                        out uint         total_matches,
                                        Cancellable?     cancellable)
                                        throws GLib.Error {
        var args = new GLib.ValueArray(0);
        var filter = this.search_expression_to_sql (expression, args);

        debug ("Orignal search: %s", expression.to_string());
        debug ("Parsed search expression: %s", filter);

        for (int i = 0; i < args.n_values; i++)
            debug ("Arg %d: %s", i, args.get_nth(i).get_string());

        var children = this.media_db.get_children_with_filter (filter,
                                                               args,
                                                               this.id,
                                                               offset,
                                                               max_count);
        foreach (var child in children) {
            child.parent = this;
        }

        return children;
    }

    private string? search_expression_to_sql (SearchExpression? expression,
                                              GLib.ValueArray args) {
        string result = null;

        if (expression == null)
            return result;

        if (expression is LogicalExpression) {
            var exp = (LogicalExpression) expression;
            string left = search_expression_to_sql (exp.operand1, args);
            string right = search_expression_to_sql (exp.operand2, args);
            result = "(%s %s %s)".printf (left,
                          expression.op == LogicalOperator.AND ? "AND" : "OR",
                          right);
        } else {
            var exp = (RelationalExpression) expression;
            string column = null;
            string func = null;
            switch (exp.operand1)
            {
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
                case "dc:creator":
                    column = "m.author";
                    break;
                case "dc:date":
                    column = "m.date";
                    break;
                default:
                    warning("Unsupported thing");
                    break;
            }
            if (column == null)
                return result;

            switch (exp.op) {
/*                case SearchCriteriaOp.EXISTS:
                    if (op.operand2 == "true")
                        func = "=";
                    else
                        func = "!=";
                    break; */
                case SearchCriteriaOp.EQ:
                    func = "=";
                    GLib.Value v;
                    v = exp.operand2;
                    args.append (v);
                    break;
                case SearchCriteriaOp.NEQ:
                    func = "=";
                    GLib.Value v;
                    v = exp.operand2;
                    args.append (v);
                    break;
                case SearchCriteriaOp.LESS:
                    func = "<";
                    GLib.Value v;
                    v = exp.operand2;
                    args.append (v);
                    break;
                case SearchCriteriaOp.LEQ:
                    func = "<=";
                    GLib.Value v;
                    v = exp.operand2;
                    args.append (v);
                    break;
                case SearchCriteriaOp.GREATER:
                    func = ">";
                    GLib.Value v;
                    v = exp.operand2;
                    args.append (v);
                    break;
                case SearchCriteriaOp.GEQ:
                    func = ">=";
                    GLib.Value v;
                    v = exp.operand2;
                    args.append (v);
                    break;
                case SearchCriteriaOp.CONTAINS:
                    func = "LIKE";
                    GLib.Value v;
                    v = "%%%s%%".printf(exp.operand2);
                    args.append (v);
                    break;
                case SearchCriteriaOp.DOES_NOT_CONTAIN:
                    func = "NOT LIKE";
                    GLib.Value v;
                    v = "%%%s%%".printf(exp.operand2);
                    args.append (v);
                    break;
                case SearchCriteriaOp.DERIVED_FROM:
                    func = "LIKE";
                    GLib.Value v;
                    v = "%s%%".printf(exp.operand2);
                    args.append (v);
                    break;
                default:
                    warning ("Unsupported op %d", exp.op);
                    break;
            }

            result = "%s %s ?".printf(column, func);
        }

        return result;
    }
}


