/*
 * Copyright (C) 2010-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
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
using Tracker;

/**
 * Represents Tracker SPARQL Selection query
 */
public class Rygel.Tracker.SelectionQuery : Query {
    public const string ITEM_VARIABLE = "?item";
    private const string SHARED_FILTER = "(!BOUND(nmm:uPnPShared(" +
                                         ITEM_VARIABLE + ")) ||" +
                                         " nmm:uPnPShared(" +
                                         ITEM_VARIABLE +
                                         ") = true) && " +
                                         "(BOUND(nie:url(" +
                                         ITEM_VARIABLE + ")))";
    private const string STRICT_SHARED_FILTER = "(BOUND(nmm:dlnaProfile(" +
                                                ITEM_VARIABLE + ")))";
    private const string AVAILABLE_FILTER = "(tracker:available(" +
                                            ITEM_VARIABLE + ") = true)";

    public ArrayList<string> variables;
    public ArrayList<string> filters;

    public string order_by;
    public int offset;
    public int max_count;

    public Sparql.Cursor result;

    public SelectionQuery (ArrayList<string>  variables,
                           QueryTriplets      triplets,
                           ArrayList<string>? filters,
                           string?            order_by = null,
                           int                offset = 0,
                           int                max_count = -1) {
        base (triplets);

        if (filters != null) {
            this.filters = filters;
        } else {
            this.filters = new ArrayList<string> ();
        }

        this.variables = variables;
        this.order_by = order_by;
        this.offset = offset;
        this.max_count = max_count;
    }

    public SelectionQuery.clone (SelectionQuery query) {
        this (copy_str_list (query.variables),
              new QueryTriplets.clone (query.triplets),
              copy_str_list (query.filters),
              query.order_by,
              query.offset,
              query.max_count);
    }

    public override async void execute (Sparql.Connection resources)
                                        throws IOError,
                                               Sparql.Error,
                                               DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        result = yield resources.query_async (str);
    }

    public override string to_string () {
        var query = "SELECT ";

        foreach (var variable in this.variables) {
            query += " " + variable;
        }

        query += " WHERE { " + base.to_string ();

        var filters = new ArrayList<string> ();
        filters.add_all (this.filters);
        // Make sure we don't expose items that are marked not to be shared
        filters.add (SHARED_FILTER);

        // Make sure we don't expose items on removable media that isn't
        // mounted
        filters.add (AVAILABLE_FILTER);

        // If strict sharing is enabled, only expose files that have a DLNA
        // profile set
        try {
            var config = MetaConfig.get_default ();
            if (config.get_bool ("Tracker", "strict-sharing")) {
                filters.add (STRICT_SHARED_FILTER);
            }
        } catch (Error error) {};

        if (filters.size > 0) {
            query += " FILTER (";
            for (var i = 0; i < filters.size; i++) {
                query += filters[i];

                if (i < filters.size - 1) {
                    query += " && ";
                }
            }
            query += ")";
        }

        query += " }";

        if (this.order_by != null) {
            query += " ORDER BY " + order_by;
        }

        if (this.offset > 0) {
            query += " OFFSET " + this.offset.to_string ();
        }

        if (this.max_count > 0) {
            query += " LIMIT " + this.max_count.to_string ();
        }

        return query;
    }

    private static ArrayList<string> copy_str_list (Gee.List<string> str_list) {
        var copy = new ArrayList<string> ();

        copy.add_all (str_list);

        return copy;
    }
}
