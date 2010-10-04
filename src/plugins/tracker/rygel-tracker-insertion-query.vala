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
public class Rygel.Tracker.InsertionQuery : Query {
    private const string TEMP_ID = "x";
    private const string QUERY_ID = "_:" + TEMP_ID;

    public string id;

    public InsertionQuery (MediaItem item, string category) {
        var triplets = new QueryTriplets ();
        triplets.add (new QueryTriplet (QUERY_ID, "a", category));
        triplets.add (new QueryTriplet (QUERY_ID, "a", "nie:DataObject"));
        triplets.add (new QueryTriplet (QUERY_ID, "a", "nfo:FileDataObject"));
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
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nfo:fileSize",
                                        "\"" + item.size.to_string () + "\""));

        var now = TimeVal ();
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nfo:fileLastModified",
                                        "\"" + now.to_iso8601 () + "\""));

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
