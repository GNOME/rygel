/*
 * Copyright (C) 2011-2012 Nokia Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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
 * Represents Tracker SPARQL Deletion query
 */
public class Rygel.Tracker.CleanupQuery : Query {
    private string category;

    public CleanupQuery (string category) {
        var triplets = new QueryTriplets ();
        triplets.add (new QueryTriplet ("?r", "a", "rdfs:Resource"));

        base (triplets);

        this.category = category;
    }

    public override async void execute (Sparql.Connection resources)
                                        throws IOError,
                                               Sparql.Error,
                                               DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        yield resources.update_async (str);
    }

    public override string to_string () {
        StringBuilder result = new StringBuilder ();

        result.append ("DELETE {");
        result.append (base.to_string ());
        result.append ("} WHERE {");
        result.append_printf ("?r a nie:DataObject, %s . ", this.category);
        result.append (" ?r nie:generator \"rygel\". ");
        result.append ("FILTER(NOT EXISTS { ?r ");
        result.append ("a nfo:FileDataObject. })}");

        return result.str;
    }
}
