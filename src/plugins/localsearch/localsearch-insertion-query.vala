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
using Tracker;

/**
 * Represents Tracker SPARQL Insertion query
 */
public class Rygel.Tracker.InsertionQuery : Query {
    private const string TEMP_ID = "x";
    private const string QUERY_ID = "_:" + TEMP_ID;

    private const string MINER_SERVICE = "org.freedesktop.Tracker3.Miner.Files.Index";
    private const string MINER_PATH = "/org/freedesktop/Tracker3/Miner/Files/Index";

    private const string MINER_GRAPH = "tracker:FileSystem";

    private const string RESOURCE_ID_QUERY_TEMPLATE =
        "SELECT ?resource WHERE { ?f a nie:DataObject; nie:url '%s'; nie:interpretedAs ?resource }";

    private const string RESOURCE_NOT_BOUND_TEMPLATE =
        "OPTIONAL { GRAPH Tracker:FileSystem { ?resource a nie:DataObject; nie:url '%s' }} " +
        "FILTER (!bound(?resource))";

    public string id;

    private string uri;

    public InsertionQuery (MediaFileItem item, string category) {
        var type = "nie:InformationElement";
        var file = File.new_for_uri (item.get_primary_uri ());
        var urn = "<%s>".printf(item.get_primary_uri ());

        if (!file.is_native ()) {
            type = "nfo:RemoteDataObject";
        }

        var triplets = new QueryTriplets ();
        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID, "a", category));
        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID, "a", type));
        //  triplets.add (new QueryTriplet (QUERY_ID, "nmm:uPnPShared", "true"));
        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID,
                                        "nie:generator",
                                        "\"rygel\""));

        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID,
                                        "nie:title",
                                        "\"" + item.title + "\""));

        var dlna_profile = "";
        if (item.dlna_profile != null) {
            dlna_profile = item.dlna_profile;
        }

        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID,
                                        "nmm:dlnaProfile",
                                        "\"" + dlna_profile + "\""));

        triplets.add (new QueryTriplet.with_graph
                                            ("Tracker:Audio",
                                                QUERY_ID,
                                                "nie:mimeType",
                                                "\"" + item.mime_type + "\""));


        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID,
                                                   "nie:isStoredAs", urn));
        string date;
        if (item.date == null) {
            var now = new GLib.DateTime.now_utc ();
            date = "%sZ".printf (now.format ("%Y-%m-%dT%H:%M:%S"));
        } else {
            // Rygel core makes sure that this is a valid ISO8601 date.
            date = item.date;
        }
        triplets.add (new QueryTriplet.with_graph ("Tracker:Audio", QUERY_ID,
                                        "nie:contentCreated",
                                        "\"" + date + "\"^^xsd:dateTime"));

        triplets.add (new QueryTriplet.with_graph (MINER_GRAPH, urn, "a", "nie:DataObject"));
        triplets.add (new QueryTriplet.with_graph (MINER_GRAPH, urn, "nie:interpretedAs", QUERY_ID));
        triplets.add (new QueryTriplet.with_graph (MINER_GRAPH, urn, "tracker:available", "true"));

        if (item.size > 0) {
            triplets.add (new QueryTriplet.with_graph
                                        (MINER_GRAPH,
                                         urn,
                                         "nie:byteSize",
                                         "\"" + item.size.to_string () + "\""));
        }

        base (triplets);

        this.uri = item.get_primary_uri ();
    }

    public override async void execute (Sparql.Connection resources)
                                        throws Error,
                                        IOError,
                                        Sparql.Error,
                                        DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        Variant v = yield resources.update_blank_async (str);
        VariantIter iter1, iter2, iter3;
        string key = null;

        debug("Result: %s", v.print(true));

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
            debug("Item already exists, running query %s", this.get_resource_id_query ().to_string ());
            var cursor = yield resources.query_async
                                        (this.get_resource_id_query ());

            try {
                while (cursor.next ()) {
                    this.id = cursor.get_string (0);
                    break;
                }
            } catch (Error error) {
                debug ("Failed to query resource: %s", error.message);
            }
            cursor.close ();
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
        //  query += "WHERE {" + RESOURCE_NOT_BOUND_TEMPLATE.printf (this.uri) +
        //             "}";

        return query;
    }

    private string get_resource_id_query () {
        return RESOURCE_ID_QUERY_TEMPLATE.printf (this.uri);
    }
}
