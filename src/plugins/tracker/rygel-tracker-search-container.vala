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
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    private const string TRACKER_PATH = "/org/freedesktop/Tracker";
    private const string SEARCH_PATH = "/org/freedesktop/Tracker/Search";
    private const string METADATA_PATH = "/org/freedesktop/Tracker/Metadata";

    public TrackerSearchIface search_proxy;

    public string service;

    public string query_condition;

    public string[] keywords;

    public TrackerSearchContainer (string         id,
                                   MediaContainer parent,
                                   string         title,
                                   string         service,
                                   string         query_condition = "",
                                   string[]       keywords = new string[0]) {
        base (id, parent, title, 0);

        this.service = service;
        this.keywords = keywords;
        this.query_condition = query_condition;

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
            // We are performing actual search (though an optimized one) to get
            // the hitcount rather than GetHitCount because GetHitCount only
            // allows us to get hit count for Text searches.
            string query;

            if (this.query_condition != "") {
                query = "<rdfq:Condition>\n" +
                            this.query_condition +
                        "</rdfq:Condition>";
            } else {
                query = "";
            }

            var search_result = yield this.search_proxy.query (
                                        0,
                                        this.service,
                                        new string[0],
                                        "",
                                        this.keywords,
                                        query,
                                        false,
                                        new string[0],
                                        false,
                                        0,
                                        -1);

            this.child_count = search_result.length[0];
            this.updated ();
        } catch (GLib.Error error) {
            critical ("error getting items under service '%s': %s",
                      this.service,
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
        string query = this.create_query_from_expression (expression);
        var results = new ArrayList<MediaObject> ();

        if (query == null) {
            /* FIXME: chain-up when bug#601558 is fixed
            return yield base.search (expression,
                                  offset,
                                  max_count,
                                  total_matches,
                                  cancellable);*/
            return results;
        }

        string[] keys = TrackerItem.get_metadata_keys ();

        var search_result = yield this.search_proxy.query (
                                        0,
                                        this.service,
                                        keys,
                                        "",
                                        this.keywords,
                                        query,
                                        false,
                                        new string[0],
                                        false,
                                        (int) offset,
                                        (int) max_count);

        /* Iterate through all items */
        for (uint i = 0; i < search_result.length[0]; i++) {
            string path = search_result[i, 0];
            string service = search_result[i, 1];
            string[] metadata = this.slice_strvv_tail (search_result, i, 2);

            var item = this.create_item (service, path, metadata);
            results.add (item);
        }

        total_matches = results.size;

        return results;
    }

    private string? create_query_from_expression (SearchExpression expression) {
        string query = null;

        if (expression == null || !(expression is RelationalExpression)) {
            return query;
        }

        var rel_expression = expression as RelationalExpression;
        var query_op = this.get_op_for_expression (rel_expression);

        if (rel_expression.operand1 == "@id" && query_op != null) {
            query = create_query_for_id (rel_expression, query_op);
        } else if (rel_expression.operand1 == "@parentID" &&
                   rel_expression.compare_string (this.id)) {
            if (this.query_condition != "") {
                query = "<rdfq:Condition>\n" +
                            this.query_condition +
                        "</rdfq:Condition>";
            } else {
                query = "";
            }
        }

        return query;
    }

    private string? create_query_for_id (RelationalExpression expression,
                                         string               query_op) {
        string query = null;
        string parent_id;
        string service;

        var path = this.get_item_info (expression.operand2,
                                       out parent_id,
                                       out service);

        if (path != null && parent_id != null && parent_id == this.id) {
            var dir = Path.get_dirname (path);
            var basename = Path.get_basename (path);

            var search_condition = "<rdfq:and>\n" +
                                        "<" + query_op + ">\n" +
                                            "<rdfq:Property " +
                                                "name=\"File:Path\" />\n" +
                                            "<rdf:String>" +
                                                dir +
                                            "</rdf:String>\n" +
                                        "</" + query_op + ">\n" +
                                        "<" + query_op + ">\n" +
                                            "<rdfq:Property " +
                                                "name=\"File:Name\" />\n" +
                                            "<rdf:String>" +
                                                basename +
                                            "</rdf:String>\n" +
                                        "</" + query_op + ">\n" +
                                   "</rdfq:and>\n";

            if (this.query_condition != "") {
                query = "<rdfq:Condition>\n" +
                            "<rdfq:and>\n" +
                                search_condition +
                                this.query_condition +
                            "</rdfq:and>\n" +
                        "</rdfq:Condition>";
            } else {
                query = "<rdfq:Condition>\n" +
                            search_condition +
                        "</rdfq:Condition>";
            }
        }

        return query;
    }

    private string? get_op_for_expression (RelationalExpression expression) {
        switch (expression.op) {
        case SearchCriteriaOp.EQ:
            return "rdfq:equals";
        case SearchCriteriaOp.CONTAINS:
            return "rdfq:contains";
        default:
            return null;
        }
    }

    private MediaItem? create_item (string   service,
                                    string   path,
                                    string[] metadata)
                                    throws GLib.Error {
        var id = service + ":" + this.id + ":" + path;

        if (service == TrackerVideoItem.SERVICE) {
            return new TrackerVideoItem (id,
                                         path,
                                         this,
                                         metadata);
        } else if (service == TrackerImageItem.SERVICE) {
            return new TrackerImageItem (id,
                                         path,
                                         this,
                                         metadata);
        } else if (service == TrackerMusicItem.SERVICE) {
            return new TrackerMusicItem (id,
                                         path,
                                         this,
                                         metadata);
        } else {
            return null;
        }
    }

    // Returns the path, ID of the parent and service this item belongs to, or
    // null item_id is invalid
    private string? get_item_info (string     item_id,
                                   out string parent_id,
                                   out string service) {
        var tokens = item_id.split (":", 3);

        if (tokens[0] != null && tokens[1] != null && tokens[2] != null) {
            service = tokens[0];
            parent_id = tokens[1];

            return tokens[2];
        } else {
            return null;
        }
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.search_proxy = connection.get_object (TRACKER_SERVICE,
                                                   SEARCH_PATH)
                                                   as TrackerSearchIface;
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

