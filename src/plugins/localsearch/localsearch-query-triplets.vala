/*
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Gee;

/**
 * Represents a list of SPARQL Triplet
 */
public class Rygel.LocalSearch.QueryTriplets : ArrayList<QueryTriplet> {
    public QueryTriplets () {
        base ((EqualDataFunc<QueryTriplet>) QueryTriplet.equal_func);
    }

    public QueryTriplets.clone (QueryTriplets triplets) {
        base ((EqualDataFunc<QueryTriplet>) QueryTriplet.equal_func);

        foreach (var triplet in triplets) {
            this.add (new QueryTriplet.clone (triplet));
        }
    }

    public string serialize () {
        string str = "";
        var include_subject = true;

        for (int i = 0; i < this.size; i++) {
            if (this[i].graph != null && include_subject) {
                str += "GRAPH %s {".printf (this[i].graph);
            }

            str += this[i].to_string (include_subject);

            if (i < this.size - 1) {
                include_subject = this[i].subject != this[i + 1].subject ||
                                  this.check_graph_change (i);

                if (include_subject) {
                    str += " . ";
                    // close the graph if we change the subject
                    if (this[i].graph != null) {
                        str += "} ";
                    }
                } else {
                    str += " ; ";
                }
            } else {
                // need to explicitly close the graph for the last triplet
                if (this[i].graph != null) {
                    str += " . } ";
                }
            }
        }

        return str;
    }

    public override bool add (QueryTriplet triplet) {
        if (!this.contains (triplet)) {
            return base.add (triplet);
        }

        return false;
    }

    private bool check_graph_change (int i) {
        return (this[i].graph == null && this[i + 1].graph != null) ||
               (this[i].graph != null && this[i + 1].graph == null) ||
               (this[i].graph != this[i + 1].graph);
    }
}
