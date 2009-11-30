/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
using DBus;
using Gee;

/**
 * A container listing a Tracker search result.
 */
public class Rygel.TrackerSearchContainer : Rygel.MediaContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";

    private const string ITEM_VARIABLE = "?item";

    public TrackerQuery query;
    public string category;

    private TrackerResourcesIface resources;

    public TrackerSearchContainer (string                id,
                                   MediaContainer        parent,
                                   string                title,
                                   string                category,
                                   TrackerQueryTriplets? mandatory = null,
                                   ArrayList<string>?    filters = null) {
        base (id, parent, title, 0);

        this.category = category;

        var variables = new ArrayList<string> ();
        variables.add (ITEM_VARIABLE);

        var our_mandatory = new TrackerQueryTriplets ();
        if (mandatory != null) {
            our_mandatory.add_all (mandatory);
        }

        our_mandatory.add (new TrackerQueryTriplet (ITEM_VARIABLE,
                                                    "a",
                                                    category,
                                                    false));

        var optional = new TrackerQueryTriplets ();
        foreach (var key in TrackerItem.get_metadata_keys ()) {
            var variable = "?" + key.replace (":", "_");

            variables.add (variable);

            var triplet = new TrackerQueryTriplet (ITEM_VARIABLE,
                                                   key,
                                                   variable);
            optional.add (triplet);
        }

        this.query = new TrackerQuery (variables,
                                       our_mandatory,
                                       optional,
                                       filters,
                                       ITEM_VARIABLE);

        try {
            this.create_proxies ();

            /* FIXME: We need to hook to some tracker signals to keep
             *        this field up2date at all times
             */
            this.get_children_count.begin ();
        } catch (DBus.Error error) {
            critical ("Failed to connect to session bus: %s\n", error.message);
        }
    }

    private async void get_children_count () {
        try {
            var query = new TrackerQuery.from_template (this.query);

            query.variables = new ArrayList<string> ();
            query.variables.add ("COUNT(" + ITEM_VARIABLE + ") AS x");
            query.optional = new TrackerQueryTriplets ();

            var query_str = query.to_string ();

            debug ("Executing SPARQL query: %s", query_str);
            var result = yield this.resources.sparql_query (query_str);

            this.child_count = result[0,0].to_int ();
            this.updated ();
        } catch (GLib.Error error) {
            critical ("error getting item count under category '%s': %s",
                      this.category,
                      error.message);

            return;
        }
    }

    public override async Gee.List<MediaObject>? get_children (
                                        uint         offset,
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

    public override async Gee.List<MediaObject>? search (
                                        SearchExpression expression,
                                        uint             offset,
                                        uint             max_count,
                                        out uint         total_matches,
                                        Cancellable?     cancellable)
                                        throws GLib.Error {
        var results = new ArrayList<MediaObject> ();
        var query = this.create_query (expression,
                                       (int) offset,
                                       (int) max_count);
        if (query == null) {
            /* FIXME: chain-up when bug#601558 is fixed
            return yield base.search (expression,
                                  offset,
                                  max_count,
                                  total_matches,
                                  cancellable);*/
            return results;
        }

        var query_str = query.to_string ();

        debug ("Executing SPARQL query: %s", query_str);
        var search_result = yield this.resources.sparql_query (query_str);

        /* Iterate through all items */
        for (uint i = 0; i < search_result.length[0]; i++) {
            string uri = search_result[i, 0];
            string[] metadata = this.slice_strvv_tail (search_result, i, 1);

            var item = this.create_item (uri, metadata);
            results.add (item);
        }

        total_matches = results.size;

        return results;
    }

    private TrackerQuery? create_query (SearchExpression expression,
                                        int              offset,
                                        int              max_count) {
        if (expression == null || !(expression is RelationalExpression)) {
            return null;
        }

        var rel_expression = expression as RelationalExpression;
        string filter = null;

        if (rel_expression.operand1 == "@id") {
            filter = create_filter_for_id (rel_expression);
        } else if (rel_expression.operand1 == "@parentID" &&
                   !rel_expression.compare_string (this.id)) {
            return null;
        }

        var query = new TrackerQuery.from_template (this.query);

        if (filter != null) {
            var filters = query.filters;
            query.filters = new ArrayList<string> ();
            query.filters.add_all (filters);
            query.filters.add (filter);
        }

        query.offset = offset;
        query.max_count = max_count;

        return query;
    }

    private string? create_filter_for_id (RelationalExpression expression) {
        string filter = null;

        switch (expression.op) {
            case SearchCriteriaOp.EQ:
                string parent_id;

                var uri = this.get_item_info (expression.operand2,
                                              out parent_id);
                if (uri == null || parent_id == null || parent_id != this.id) {
                    break;
                }

                filter = ITEM_VARIABLE + " = " + uri;
                break;
            case SearchCriteriaOp.CONTAINS:
                filter = "regex(" + ITEM_VARIABLE + ", " +
                                    expression.operand2 +
                         ")";
                break;
        }

        return filter;
    }

    private MediaItem? create_item (string   uri,
                                    string[] metadata)
                                    throws GLib.Error {
        var id = this.id + ":" + uri;

        if (this.category == TrackerVideoItem.CATEGORY) {
            return new TrackerVideoItem (id,
                                         uri,
                                         this,
                                         metadata);
        } else if (this.category == TrackerImageItem.CATEGORY) {
            return new TrackerImageItem (id,
                                         uri,
                                         this,
                                         metadata);
        } else if (this.category == TrackerMusicItem.CATEGORY) {
            return new TrackerMusicItem (id,
                                         uri,
                                         this,
                                         metadata);
        } else {
            return null;
        }
    }

    // Returns the URI and the ID of the parent this item belongs to, or null
    // if item_id is invalid
    private string? get_item_info (string     item_id,
                                   out string parent_id) {
        var tokens = item_id.split (":", 2);

        if (tokens[0] != null && tokens[1] != null) {
            parent_id = tokens[0];

            return tokens[1];
        } else {
            return null;
        }
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.resources = connection.get_object (TRACKER_SERVICE,
                                                RESOURCES_PATH)
                                                as TrackerResourcesIface;
    }

    /**
     * Chops the tail of a particular row in a 2-dimensional string array.
     *
     * param strvv the 2-dimenstional string array to chop the tail of.
     * param row the row whose tail needs to be chopped off.
     * param index index of the first element in the tail.
     *
     * FIXME: Stop using it once vala supports array[N:M] syntax.
     */
    private string[] slice_strvv_tail (string[,] strvv, uint row, uint index) {
        var slice = new string[strvv.length[1] - index];

        for (var i = 0; i < slice.length; i++) {
            slice[i] = strvv[row, i + index];
        }

        return slice;
    }
}

