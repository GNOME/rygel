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
    private const string TEMP_ID = "x";
    private const string QUERY_ID = "_:" + TEMP_ID;

    public string id;

    public TrackerInsertionQuery (MediaItem item, string category) {
        var triplets = new TrackerQueryTriplets ();
        triplets.add (new TrackerQueryTriplet (QUERY_ID,
                                               "a",
                                               category,
                                               false));
        triplets.add (new TrackerQueryTriplet (QUERY_ID,
                                               "a",
                                               "nie:DataObject",
                                               false));
        triplets.add (new TrackerQueryTriplet (QUERY_ID,
                                               "a",
                                               "nfo:FileDataObject",
                                               false));
        triplets.add (new TrackerQueryTriplet (QUERY_ID,
                                               "nie:mimeType",
                                               "\"" + item.mime_type + "\"",
                                               false));
        triplets.add (new TrackerQueryTriplet (QUERY_ID,
                                               "nie:url",
                                               "\"" + item.uris[0] + "\"",
                                               false));

        var now = TimeVal ();
        triplets.add (new TrackerQueryTriplet (QUERY_ID,
                                               "nfo:fileLastModified",
                                               "\"" + now.to_iso8601 () + "\"",
                                               false));

        base (triplets, null);
    }

    public override async void execute (TrackerResourcesIface resources)
                                        throws DBus.Error {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        var result = yield resources.sparql_update_blank (str);

        this.id = result[0,0].lookup (TEMP_ID);
    }

    public override string to_string () {
        return "INSERT { " + base.to_string () + " }";
    }
}
