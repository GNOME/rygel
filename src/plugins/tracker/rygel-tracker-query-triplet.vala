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
 * Represents SPARQL Triplet
 */
public class Rygel.TrackerQueryTriplet {
    public string subject;
    public string predicate;
    public string obj;

    public bool optional;

    public TrackerQueryTriplet (string? subject,
                                string  predicate,
                                string  obj,
                                bool    optional = true) {
        this.subject = subject;
        this.predicate = predicate;
        this.obj = obj;
        this.optional = optional;
    }

    public TrackerQueryTriplet.clone (TrackerQueryTriplet triplet) {
        this (triplet.subject,
              triplet.predicate,
              triplet.obj,
              triplet.optional);
    }

    public static bool equal_func (TrackerQueryTriplet a,
                                   TrackerQueryTriplet b) {
        return a.subject == b.subject &&
               a.obj == b.obj &&
               a.predicate == b.predicate &&
               a.optional == b.optional;
    }

    public string to_string () {
        string str = "";

        if (this.optional) {
            str += "OPTIONAL {";
        }

        if (this.subject != null) {
            str += " " + subject;
        }

        str += " " + predicate + " " + obj;

        if (this.optional) {
            str += " }";
        }

        return str;
    }
}
