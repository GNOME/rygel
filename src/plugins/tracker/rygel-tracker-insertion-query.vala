/*
 * Copyright (C) 2010-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
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
 * Represents Tracker SPARQL Insertion query
 */
public class Rygel.Tracker.InsertionQuery : Query {
    private const string TEMP_ID = "x";
    private const string QUERY_ID = "_:" + TEMP_ID;

    private const string MINER_SERVICE = "org.freedesktop.Tracker1.Miner.Files.Index";
    private const string MINER_PATH = "/org/freedesktop/Tracker1/Miner/Files/Index";

    // We need to add the size in the miner's graph so that the miner will
    // update it and correct a (possibly wrong) size we got via CreateItem
    // (DLNA requirement 7.3.128.7)
    // FIXME: Use constant from libtracker-miner once we port to
    // libtracker-sparql
    private const string MINER_GRAPH =
                              "urn:uuid:472ed0cc-40ff-4e37-9c0c-062d78656540";

    private const string RESOURCE_ID_QUERY_TEMPLATE =
        "SELECT ?resource WHERE { ?resource a nie:DataObject; nie:url '%s' }";

    private const string RESOURCE_NOT_BOUND_TEMPLATE =
        "OPTIONAL { ?resource a nie:DataObject; nie:url '%s' } " +
        "FILTER (!bound(?resource))";

    public string id;

    private string uri;

    public InsertionQuery (MediaItem item, string category) {
        var type = "nie:DataObject";
        var file = File.new_for_uri (item.uris[0]);

        if (!file.is_native ()) {
            type = "nfo:RemoteDataObject";
        }

        var triplets = new QueryTriplets ();
        triplets.add (new QueryTriplet (QUERY_ID, "a", category));
        triplets.add (new QueryTriplet (QUERY_ID, "a", type));
        triplets.add (new QueryTriplet (QUERY_ID, "nmm:uPnPShared", "true"));
        triplets.add (new QueryTriplet (QUERY_ID, "tracker:available", "true"));
        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:generator",
                                        "\"rygel\""));

        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:title",
                                        "\"" + item.title + "\""));

        triplets.add (new QueryTriplet.with_graph
                                        (MINER_GRAPH,
                                         QUERY_ID,
                                         "nie:mimeType",
                                         "\"" + item.mime_type + "\""));
        var dlna_profile = "";
        if (item.dlna_profile != null) {
            dlna_profile = item.dlna_profile;
        }

        triplets.add (new QueryTriplet.with_graph
                                        (MINER_GRAPH,
                                         QUERY_ID,
                                         "nmm:dlnaProfile",
                                         "\"" + dlna_profile + "\""));

        triplets.add (new QueryTriplet (QUERY_ID,
                                        "nie:url",
                                        "\"" + item.uris[0] + "\""));
        string date;
        if (item.date == null) {
            var now = TimeVal ();
            date = now.to_iso8601 ();
        } else {
            // Rygel core makes sure that this is a valid ISO8601 date.
            date = item.date;
        }
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

        this.uri = item.uris[0];
    }

    public override async void execute (Sparql.Connection resources)
                                        throws IOError,
                                        Sparql.Error,
                                        DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        Variant v = yield resources.update_blank_async (str);
        VariantIter iter1, iter2, iter3;
        string key = null;

        iter1 = v.iterator ();
        while (iter1.next ("aa{ss}", out iter2)) {
            while (iter2.next ("a{ss}", out iter3)) {
                while (iter3.next ("{ss}", out key, out this.id)) {
                    break;
                }
            }
        }

        // Item already existed
        if (this.id == null)  {
            var cursor = yield resources.query_async
                                        (this.get_resource_id_query ());

            try {
                while (cursor.next ()) {
                    this.id = cursor.get_string (0);
                    break;
                }
            } catch (Error error) {
            }
        } else {
            var file = File.new_for_uri (this.uri);
            if (file.is_native () &&
                file.query_exists ()) {
                MinerFilesIndexIface miner  = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         MINER_SERVICE,
                                         MINER_PATH,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
                miner.index_file.begin (this.uri);
            }
        }

        debug ("Created item in Tracker store with ID '%s'", this.id);
    }

    public override string to_string () {
        var query = "INSERT { " + base.to_string () + " }";
        query += "WHERE {" + RESOURCE_NOT_BOUND_TEMPLATE.printf (this.uri) +
                 "}";

        return query;
    }

    private string get_resource_id_query () {
        return RESOURCE_ID_QUERY_TEMPLATE.printf (this.uri);
    }
}
