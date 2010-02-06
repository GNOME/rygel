/*
 * Copyright (C) 20010 Nokia Corporation.
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
 * Represents Tracker SPARQL Insertion query
 */
public class Rygel.TrackerInsertionQuery : Rygel.TrackerQuery {
    public string id;

    public TrackerInsertionQuery (MediaItem item, string category) {
        var triplets = new TrackerQueryTriplets ();
        triplets.add (new TrackerQueryTriplet (item.id,
                                               "a",
                                               category,
                                               false));
        triplets.add (new TrackerQueryTriplet (item.id,
                                               "nie:mimeType",
                                               "\"" + item.mime_type + "\"",
                                               false));
        triplets.add (new TrackerQueryTriplet (item.id,
                                               "nie:url",
                                               "\"" + item.uris[0] + "\"",
                                               false));
        base (triplets, null);

        this.id = item.id;
    }

    public override async void execute (TrackerResourcesIface resources)
                                        throws DBus.Error {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        yield resources.sparql_update (str);
    }

    public override string to_string () {
        return "INSERT INTO " +  this.id + " { " + base.to_string () + " }";
    }
}
