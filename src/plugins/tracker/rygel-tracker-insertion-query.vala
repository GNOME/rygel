/*
 * Copyright (C) 2010 Nokia Corporation.
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
public class Rygel.Tracker.InsertionQuery : Query {
    private const string TEMP_ID = "x";
    private const string QUERY_ID = "_:" + TEMP_ID;

    // We need to add the size in the miner's graph so that the miner will
    // update it and correct a (possibly wrong) size we got via CreateItem
    // (DLNA requirement 7.3.128.7)
    // FIXME: Use constant from libtracker-miner once we port to
    // libtracker-sparql
    private const string MINER_GRAPH =
                              "urn:uuid:472ed0cc-40ff-4e37-9c0c-062d78656540";

    public string id;

    public InsertionQuery (MediaItem item, string category) {
        var triplets = new QueryTriplets ();
        triplets.add (new QueryTriplet (QUERY_ID, "a", category));
        triplets.add (new QueryTriplet (QUERY_ID, "a", "nie:DataObject"));
        triplets.add (new QueryTriplet (QUERY_ID, "nmm:uPnPShared", "true"));
        triplets.add (new QueryTriplet (QUERY_ID, "tracker:available", "true"));
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:generator",
                                        "\"rygel\""));

        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:title",
                                        "\"" + item.title + "\""));
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:mimeType",
                                        "\"" + item.mime_type + "\""));
        if (item.dlna_profile != null) {
            triplets.add (new QueryTriplet (QUERY_ID,
                                            "nmm:dlnaProfile",
                                            "\"" + item.dlna_profile + "\""));
        }
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:url",
                                        "\"" + item.uris[0] + "\""));
        var now = TimeVal ();
        var date = now.to_iso8601 ();
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:contentCreated",
                                        "\"" + date + "\""));

        if (item.size > 0) {
            triplets.add (new QueryTriplet.with_graph
                                        (MINER_GRAPH,
                                         QUERY_ID,
                                         "nie:byteSize",
                                         "\"" + item.size.to_string () + "\""));
        }

        base (triplets);
    }

    public override async void execute (ResourcesIface resources)
                                        throws IOError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        var result = yield resources.sparql_update_blank (str);

        this.id = result[0,0].lookup (TEMP_ID);

        debug ("Created item in Tracker store with ID '%s'", this.id);
    }

    public override string to_string () {
        return "INSERT { " + base.to_string () + " }";
    }
}
