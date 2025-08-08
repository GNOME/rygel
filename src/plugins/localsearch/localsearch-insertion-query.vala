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
 * Represents LocalSearch SPARQL Insertion query
 */
public class Rygel.LocalSearch.InsertionQuery : Query {
    private const string MINER_SERVICE = "org.freedesktop.LocalSearch3.Miner.Files.Index";
    private const string MINER_PATH = "/org/freedesktop/LocalSearch3/Miner/Files/Index";

    private const string MINER_GRAPH = "tracker:FileSystem";

    public string id = null;

    private string uri;

    public InsertionQuery (MediaFileItem item, string category, string graph) {
        var uuid = GLib.Uuid.string_random ();
        var id = "urn:rygel_upload:%s".printf (uuid);
        var type = "nie:InformationElement";
        var file = File.new_for_uri (item.get_primary_uri ());
        var urn = "<%s>".printf (item.get_primary_uri ());

        if (!file.is_native ()) {
            type = "nfo:RemoteDataObject";
        }

        var triplets = new QueryTriplets ();
        triplets.add (new QueryTriplet.with_graph (graph, id, "a", category));
        triplets.add (new QueryTriplet.with_graph (graph, id, "a", type));
        //  triplets.add (new QueryTriplet (id, "nmm:uPnPShared", "true"));
        triplets.add (new QueryTriplet.with_graph (graph, id,
                                                   "nie:generator",
                                                   "\"rygel\""));

        triplets.add (new QueryTriplet.with_graph (graph, id,
                                                   "nie:title",
                                                   "\"" + item.title + "\""));

        var dlna_profile = "";
        if (item.dlna_profile != null) {
            dlna_profile = item.dlna_profile;
        }

        triplets.add (new QueryTriplet.with_graph (graph, id,
                                                   "nmm:dlnaProfile",
                                                   "\"" + dlna_profile + "\""));

        triplets.add (new QueryTriplet.with_graph
                          (graph,
                          id,
                          "nie:mimeType",
                          "\"" + item.mime_type + "\""));


        triplets.add (new QueryTriplet.with_graph (graph, id,
                                                   "nie:isStoredAs", urn));
        string date;
        if (item.date == null) {
            var now = new GLib.DateTime.now_utc ();
            date = "%sZ".printf (now.format ("%Y-%m-%dT%H:%M:%S"));
        } else {
            // Rygel core makes sure that this is a valid ISO8601 date.
            date = item.date;
        }
        triplets.add (new QueryTriplet.with_graph (graph, id,
                                                   "nie:contentCreated",
                                                   "\"" + date + "\"^^xsd:dateTime"));

        triplets.add (new QueryTriplet.with_graph (MINER_GRAPH, urn, "a", "nie:DataObject"));
        triplets.add (new QueryTriplet.with_graph (MINER_GRAPH, urn, "nie:interpretedAs", id));

        if (item.size > 0) {
            triplets.add (new QueryTriplet.with_graph
                              (MINER_GRAPH,
                              urn,
                              "nie:byteSize",
                              "\"" + item.size.to_string () + "\""));
        }

        base (triplets);

        this.uri = item.get_primary_uri ();
        this.id = id;
    }

    public override async void execute (SparqlConnection resources) throws Error,
    IOError,
    SparqlError,
    DBusError {
        var str = this.to_string ();

        debug ("Executing SPARQL query: %s", str);

        yield resources.update_async (str);

        var file = File.new_for_uri (this.uri);
        if (file.is_native () && file.query_exists ()) {
            var miner = yield Bus.get_proxy<MinerFilesIndexIface> (BusType.SESSION,
                                                                   MINER_SERVICE,
                                                                   MINER_PATH,
                                                                   DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
            miner.index_file.begin (this.uri);
        }

        debug ("Created item in LocalSearch store with ID '%s'", this.id);
    }

    public override string to_string () {
        var query = "INSERT { " + base.to_string () + " }";

        return query;
    }
}


