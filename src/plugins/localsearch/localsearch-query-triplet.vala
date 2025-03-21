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
 * Represents SPARQL Triplet
 */
public class Rygel.LocalSearch.QueryTriplet {
    public string graph;
    public string subject;
    public string predicate;
    public string obj;

    public QueryTriplet next;

    public QueryTriplet (string subject, string predicate, string obj) {
        this.graph = null;
        this.subject = subject;
        this.predicate = predicate;
        this.obj = obj;
    }

    public QueryTriplet.with_graph (string graph,
                                    string subject,
                                    string predicate,
                                    string object) {
        this.graph = graph;
        this.subject = subject;
        this.predicate = predicate;
        this.obj = object;
    }

    public QueryTriplet.chain (string       subject,
                               string       predicate,
                               QueryTriplet next) {
        this.subject = subject;
        this.predicate = predicate;
        this.next = next;
    }

    public QueryTriplet.clone (QueryTriplet triplet) {
        this.graph = triplet.graph;
        this.subject = triplet.subject;
        this.predicate = triplet.predicate;

        if (triplet.next != null) {
            this.next = triplet.next;
        } else {
            this.obj = triplet.obj;
        }
    }

    public static bool equal_func (QueryTriplet a, QueryTriplet b) {
        bool chain_equal;

        if (a.next != null && b.next != null) {
            chain_equal = equal_func (a.next, b.next);
        } else {
            chain_equal = a.next == b.next;
        }

        return a.graph == b.graph &&
               a.subject == b.subject &&
               a.obj == b.obj &&
               a.predicate == b.predicate &&
               chain_equal;
    }

    public string to_string (bool include_subject = true) {
        string str = "";

        if (include_subject) {
            str += " " + subject;
        }

        str += " " + predicate;

        if (this.next != null) {
            str += " [ " + this.next.to_string () + " ] ";
        } else {
            str += " " + this.obj;
        }

        return str;
    }
}
