/*
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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
 * Represents Tracker SPARQL search query
 *
 * FIXME: This does pretty much the same thing as selection query and
 * should eventually replace it.
 */
public class Rygel.Tracker.SearchQuery : Query {
    public const string ITEM_VARIABLE = "?item";
    private const string SHARED_FILTER = "(!BOUND(nmm:uPnPShared(" +
                                         ITEM_VARIABLE + ")) ||" +
                                         " nmm:uPnPShared(" +
                                         ITEM_VARIABLE +
                                         ") = true)";

    public ArrayList<ArrayList<string>> key_chains;
    public QueryFilter filter;
    public string order_by;
    public uint offset;
    public uint max_count;

    public string[,] result;

    public SearchQuery (ArrayList<ArrayList<string>>? key_chains,
                        QueryTriplets                 triplets,
                        QueryFilter?                  filter,
                        string?                       order_by = null,
                        uint                          offset = 0,
                        uint                          max_count = 0,
                        Cancellable?                  cancellable) {
        base (triplets);

        this.key_chains = key_chains;
        this.filter = filter;
        this.order_by = order_by;
        this.offset = offset;
        this.max_count = max_count;
    }

    public override async void execute (ResourcesIface resources)
                                        throws IOError {
        var str = this.to_string_with_count ();

        debug ("Executing SPARQL search query: %s", str);

        this.result = yield resources.sparql_query (str);
    }

    public async uint get_count (ResourcesIface resources) throws IOError {
        var str = this.to_string_with_count (true);

        debug ("Executing SPARQL search query for count: %s", str);

        var count_result = yield resources.sparql_query (str);

        return int.parse (count_result[0,0]);
    }

    public override string to_string () {
        return this.to_string_with_count ();
    }

    private string to_string_with_count (bool counting = false) {
        var query = "SELECT";

        if (counting) {
            query += " COUNT(" + this.ITEM_VARIABLE + ")";
        } else {
            query += " " + this.ITEM_VARIABLE;
            foreach (var chain in this.key_chains) {
                var variable = this.ITEM_VARIABLE;
                foreach (var key in chain) {
                    variable = key + "(" + variable + ")";
                }
                query += " " + variable;
            }
        }

        query += " WHERE {";

        if (this.triplets != null) {
            query += triplets.serialize ();
        }

        if (this.filter != null) {
            var str = this.filter.to_string ();
            query += " FILTER (" + this.SHARED_FILTER + " && (" + str + "))";
        }

        query += " }";

        if (!counting) {
            if (this.order_by != null) {
                query += " ORDER BY " + order_by;
            }

            if (this.offset > 0) {
                query += " OFFSET " + this.offset.to_string ();
            }

            if (this.max_count > 0) {
                query += " LIMIT " + this.max_count.to_string ();
            }
        }

        return query;
    }
}
