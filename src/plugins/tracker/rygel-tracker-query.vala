/*
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

using Gee;

/**
 * Represents Tracker SPARQL query
 */
public class Rygel.TrackerQuery {
    public TrackerQueryTriplets mandatory;
    public TrackerQueryTriplets optional;

    public ArrayList<string> variables;
    public ArrayList<string> filters;

    public string order_by;
    public int offset;
    public int max_count;

    public TrackerQuery (ArrayList<string>     variables,
                         TrackerQueryTriplets  mandatory,
                         TrackerQueryTriplets? optional,
                         ArrayList<string>?    filters,
                         string?               order_by = null,
                         int                   offset = 0,
                         int                   max_count = -1) {
        this.variables = variables;
        this.mandatory = mandatory;

        if (optional != null) {
            this.optional = optional;
        } else {
            this.optional = new TrackerQueryTriplets ();
        }

        if (filters != null) {
            this.filters = filters;
        } else {
            this.filters = new ArrayList<string> ();
        }

        this.order_by = order_by;

        this.offset = offset;
        this.max_count = max_count;
    }

    public TrackerQuery.clone (TrackerQuery query) {
        this (this.copy_str_list (query.variables),
              new TrackerQueryTriplets.clone (query.mandatory),
              new TrackerQueryTriplets.clone (query.optional),
              this.copy_str_list (query.filters),
              query.order_by,
              query.offset,
              query.max_count);
    }

    public string to_string () {
        string query = "SELECT";

        foreach (var variable in this.variables) {
            query += " " + variable;
        }

        query += " WHERE { " +
                 this.serialize_triplets (this.mandatory) +
                 " . " +
                 this.serialize_triplets (this.optional);

        foreach (var filter in this.filters) {
            query += " " + filter;
        }

        query += " }";

        if (this.order_by != null) {
            query += " ORDER BY " + order_by;
        }

        query += " OFFSET " + this.offset.to_string ();

        if (this.max_count != -1) {
            query += " LIMIT " + this.max_count.to_string ();
        }

        return query;
    }

    private string serialize_triplets (TrackerQueryTriplets triplets) {
        string str = "";

        for (int i = 0; i < triplets.size; i++) {
            str += triplets[i].to_string ();

            if (i < triplets.size - 1) {
                if (triplets[i + 1].subject != null) {
                    str += " . ";
                } else {
                    // This implies that next triplet shares the subject with
                    // this one so we need to end this one with a semi-colon.
                    str += " ; ";
                }
            }
        }

        return str;
    }

    private ArrayList<string> copy_str_list (Gee.List<string> str_list) {
        var copy = new ArrayList<string> ();

        copy.add_all (str_list);

        return copy;
    }
}
