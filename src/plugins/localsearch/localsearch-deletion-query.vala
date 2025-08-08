/*
 * Copyright (C) 2010-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
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
using Tsparql;

/**
 * Represents LocalSearch SPARQL Deletion query
 */
public class Rygel.LocalSearch.DeletionQuery : Query {
    private string id;

    public DeletionQuery (string id) {
        var triplets = new QueryTriplets ();

        triplets.add (new QueryTriplet ("<" + id + ">", "a", "rdfs:Resource"));

        base (triplets);

        this.id = id;
    }

    public override async void execute (SparqlConnection resources)
    throws Error,
    IOError,
    SparqlError,
    DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        yield resources.update_async (str);

        debug ("Deleted item '%s' from LocalSearch store", this.id);
    }

    public override string to_string () {
        return "DELETE { " + base.to_string () + " }";
    }
}


