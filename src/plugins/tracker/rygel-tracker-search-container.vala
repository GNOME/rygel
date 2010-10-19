/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Ivan Frade <ivan.frade@nokia.com>
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
using Gee;

/**
 * A container listing a Tracker search result.
 */
public class Rygel.Tracker.SearchContainer : Rygel.MediaContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";

    private const string MODIFIED_PREDICATE = "nfo:fileLastModified";
    private const string MODIFIED_VARIABLE = "?modified";
    private const string URL_PREDICATE = "nie:url";
    private const string URL_VARIABLE = "?url";

    public SelectionQuery query;
    public ItemFactory item_factory;

    private ResourcesIface resources;

    public SearchContainer (string             id,
                            MediaContainer     parent,
                            string             title,
                            ItemFactory        item_factory,
                            QueryTriplets?     triplets = null,
                            ArrayList<string>? filters = null) {
        base (id, parent, title, 0);

        this.item_factory = item_factory;

        var variables = new ArrayList<string> ();
        variables.add (SelectionQuery.ITEM_VARIABLE);
        variables.add (URL_VARIABLE);

        QueryTriplets our_triplets;
        if (triplets != null) {
            our_triplets = triplets;
        } else {
            our_triplets = new QueryTriplets ();
        }

        our_triplets.add_triplet (new QueryTriplet
                                        (SelectionQuery.ITEM_VARIABLE,
                                         "a",
                                         item_factory.category));
        our_triplets.add_triplet (new QueryTriplet
                                        (SelectionQuery.ITEM_VARIABLE,
                                         MODIFIED_PREDICATE,
                                         MODIFIED_VARIABLE));
        our_triplets.add_triplet (new QueryTriplet
                                        (SelectionQuery.ITEM_VARIABLE,
                                         URL_PREDICATE,
                                         URL_VARIABLE));

        foreach (var chain in this.item_factory.key_chains) {
            var variable = SelectionQuery.ITEM_VARIABLE;

            foreach (var key in chain) {
                variable = key + "(" + variable + ")";
            }

            variables.add (variable);
        }

        this.query = new SelectionQuery (variables,
                                         our_triplets,
                                         filters,
                                         MODIFIED_VARIABLE);

        try {
            this.resources = Bus.get_proxy_sync (BusType.SESSION,
                                                 TRACKER_SERVICE,
                                                 RESOURCES_PATH);

            this.get_children_count.begin ();
        } catch (IOError error) {
            critical (_("Failed to connect to session bus: %s"), error.message);
        }
    }

    public override async MediaObjects? get_children (uint         offset,
                                                      uint         max_count,
                                                      Cancellable? cancellable)
                                                      throws GLib.Error {
        var expression = new RelationalExpression ();
        expression.op = SearchCriteriaOp.EQ;
        expression.operand1 = "@parentID";
        expression.operand2 = this.id;

        uint total_matches;

        return yield this.search (expression,
                                  offset,
                                  max_count,
                                  out total_matches,
                                  cancellable);
    }

    public override async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                out uint          total_matches,
                                                Cancellable?      cancellable)
                                                throws GLib.Error {
        var results = new MediaObjects ();

        if (expression == null || !(expression is RelationalExpression)) {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      cancellable);
        }

        var query = this.create_query (expression as RelationalExpression,
                                       (int) offset,
                                       (int) max_count);
        if (query != null) {
            yield query.execute (this.resources);

            /* Iterate through all items */
            for (uint i = 0; i < query.result.length[0]; i++) {
                var id = this.create_child_id_for_urn (query.result[i, 0]);
                var uri = query.result[i, 1];
                string[] metadata = this.slice_strvv_tail (query.result, i, 2);

                var item = this.item_factory.create (id, uri, this, metadata);
                results.add (item);
            }
        }

        total_matches = results.size;

        return results;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws GLib.Error {
        if (this.is_our_child (id)) {
            return yield base.find_object (id, cancellable);
        } else {
            return null;
        }
    }

    public override async void add_item (MediaItem item,
                                         Cancellable? cancellable)
                                         throws Error {
        throw new ContentDirectoryError.RESTRICTED_PARENT (
                                        _("Object creation in %s not allowed"),
                                        this.id);
    }

    public string create_child_id_for_urn (string urn) {
        return this.id + "," + urn;
    }

    private bool is_our_child (string id) {
        return id.has_prefix (this.id + ",");
    }

    private async void get_children_count () {
        try {
            var query = new SelectionQuery.clone (this.query);

            query.variables = new ArrayList<string> ();
            query.variables.add ("COUNT(" + SelectionQuery.ITEM_VARIABLE + ") AS x");

            yield query.execute (this.resources);

            this.child_count = query.result[0,0].to_int ();
            this.updated ();
        } catch (GLib.Error error) {
            critical (_("Error getting item count under category '%s': %s"),
                      this.item_factory.category,
                      error.message);

            return;
        }
    }

    private SelectionQuery? create_query (RelationalExpression? expression,
                                          int                   offset,
                                          int                   max_count) {
        if (expression.operand1 == "upnp:class" &&
            !this.item_factory.upnp_class.has_prefix (expression.operand2)) {
            return null;
        }

        var query = new SelectionQuery.clone (this.query);

        if (expression.operand1 == "@parentID") {
            if (!expression.compare_string (this.id)) {
                return null;
            }
        } else if (expression.operand1 != "upnp:class") {
            var filter = create_filter_for_child (expression);
            if (filter != null) {
                query.filters.insert (0, filter);
            } else {
                return null;
            }
        }

        query.offset = offset;
        query.max_count = max_count;

        return query;
    }

    private string? create_filter_for_child (RelationalExpression expression) {
        string filter = null;
        string variable = null;
        string value = null;

        if (expression.operand1 == "@id") {
            variable = SelectionQuery.ITEM_VARIABLE;

            string parent_id;

            var urn = this.get_item_info (expression.operand2, out parent_id);
            if (urn == null || parent_id == null || parent_id != this.id) {
                return null;
            }

            switch (expression.op) {
                case SearchCriteriaOp.EQ:
                    value = "<" + urn + ">";
                    break;
                case SearchCriteriaOp.CONTAINS:
                    value = expression.operand2;
                    break;
            }
        }

        if (variable == null || value == null) {
            return null;
        }

        switch (expression.op) {
            case SearchCriteriaOp.EQ:
                filter = variable + " = " + value;
                break;
            case SearchCriteriaOp.CONTAINS:
                // We need to escape this twice for Tracker
                var regex = this.escape_string (Regex.escape_string (value));

                filter = "regex(" + variable + ", \"" + regex + "\", \"i\")";
                break;
        }

        return filter;
    }

    // Returns the URN and the ID of the parent this item belongs to, or null
    // if item_id is invalid
    private string? get_item_info (string     item_id,
                                   out string parent_id) {
        var tokens = item_id.split (",", 2);

        if (tokens[0] != null && tokens[1] != null) {
            parent_id = tokens[0];

            return tokens[1];
        } else {
            return null;
        }
    }

    /**
     * Chops the tail of a particular row in a 2-dimensional string array.
     *
     * param strvv the 2-dimenstional string array to chop the tail of.
     * param row the row whose tail needs to be chopped off.
     * param index index of the first element in the tail.
     *
     * FIXME: Stop using it once vala supports array slicing syntax for
     *        multi-dimentional arrays.
     */
    private string[] slice_strvv_tail (string[,] strvv, uint row, uint index) {
        var slice = new string[strvv.length[1] - index];

        for (var i = 0; i < slice.length; i++) {
            slice[i] = strvv[row, i + index];
        }

        return slice;
    }

    /**
     * tracker_sparql_escape_string:
     * @literal: a string to escape
     *
     * Escapes a string so that it can be used in a SPARQL query. Copied from
     * Tracker project.
     *
     * Returns: a newly-allocated string with the escaped version of @literal.
     *  The returned string should be freed with g_free() when no longer needed.
     */
    private string escape_string (string literal) {
        StringBuilder str = new StringBuilder ();
        char *p = literal;

        while (*p != '\0') {
            size_t len = Posix.strcspn ((string) p, "\t\n\r\b\f\"\\");
            str.append_len ((string) p, (long) len);
            p += len;

            switch (*p) {
                case '\t':
                    str.append ("\\t");
                    break;
                case '\n':
                    str.append ("\\n");
                    break;
                case '\r':
                    str.append ("\\r");
                    break;
                case '\b':
                    str.append ("\\b");
                    break;
                case '\f':
                    str.append ("\\f");
                    break;
                case '"':
                    str.append ("\\\"");
                    break;
                case '\\':
                    str.append ("\\\\");
                    break;
                default:
                    continue;
            }

            p++;
        }

        return str.str;
    }
}

