/*
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2012 Jens Georg <mail@jensge.org>
 *
 * Author: Sunil Mohan Adapa <sunil@medhas.org>
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

internal class Rygel.LocalSearch.QueryVariable {
    public string base_variable;
    public string alias;

    public QueryVariable(string base_variable, string alias) {
        this.base_variable = base_variable;
        this.alias = alias;
    }
}

/**
 * A map of UPnP properties to tracker property functions, coalesces,
 * subqueries or other custom functions
 */
public class Rygel.LocalSearch.UPnPPropertyMap : Object {
    HashMap<string, ArrayList<string>> property_map;
    HashMap<string, string> functions;
    HashMap<string, QueryVariable> variables;
    private static UPnPPropertyMap instance;

    public static UPnPPropertyMap get_property_map () {
        if (unlikely (instance == null)) {
            instance = new UPnPPropertyMap ();
        }

        return instance;
    }

    private UPnPPropertyMap () {
        this.property_map = new HashMap<string, ArrayList<string>> ();
        this.functions = new HashMap<string, string> ();
        this.variables = new HashMap<string, QueryVariable> ();

        this.add_variable ("upnp:class", SelectionQuery.ITEM_VARIABLE, "?_cls");

        // Item
        this.add_variable ("res", SelectionQuery.STORAGE_VARIABLE, "?_url");
        this.add_function ("place_holder",
                      "tracker:coalesce((SELECT false WHERE { { %s a ?o } " +
                      "FILTER (?o IN (nfo:FileDataObject, " +
                      "nfo:RemoteDataObject)) }), true)");
        this.add_variable ("place_holder", SelectionQuery.STORAGE_VARIABLE, "?_ph");
        this.add_key_chain ("fileName", "nfo:fileName");
        this.add_variable ("fileName", SelectionQuery.STORAGE_VARIABLE, "?_fn");

        this.add_alternative ("dc:title", "nie:title", "?_fn");
        this.add_function ("dc:title", "tracker:coalesce(nie:title(%s), nfo:fileName(?storage))");
        this.add_variable ("dc:title", SelectionQuery.ITEM_VARIABLE, "?_title");

        this.add_key_chain ("dlnaProfile", "nmm:dlnaProfile");
        this.add_variable ("dlnaProfile", SelectionQuery.ITEM_VARIABLE, "?_profile");

        this.add_alternative ("mimeType", "nmm:dlnaMime", "nie:mimeType");
        this.add_variable ("mimeType", SelectionQuery.ITEM_VARIABLE, "?_mime");

        this.add_alternative ("res@size", "nfo:fileSize", "nie:byteSize");
        this.add_variable ("res@size", SelectionQuery.STORAGE_VARIABLE, "?_mime");

        this.add_function ("date", "tracker:coalesce(nie:contentCreated(%s), nfo:fileLastModified(?storage))");
        this.add_variable ("date", SelectionQuery.ITEM_VARIABLE, "?_date");

        // Music Item
        this.add_key_chain ("res@duration", "nfo:duration");
        this.add_variable ("res@duration", SelectionQuery.ITEM_VARIABLE, "?_duration");

        this.add_key_chain ("upnp:artist", "nmm:performer", "nmm:artistName");
        this.add_variable ("upnp:artist", SelectionQuery.ITEM_VARIABLE, "?_artist");

        this.add_key_chain ("dc:creator", "nmm:performer", "nmm:artistName");
        this.add_variable ("dc:creator", SelectionQuery.ITEM_VARIABLE, "?_artist");

        this.add_key_chain ("upnp:album", "nmm:musicAlbum", "nie:title");
        this.add_variable ("upnp:album", SelectionQuery.ITEM_VARIABLE, "?_album");

        this.add_key_chain ("upnp:originalTrackNumber", "nmm:trackNumber");
        this.add_variable ("upnp:originalTrackNumber", SelectionQuery.ITEM_VARIABLE, "?_track");

        this.add_key_chain ("upnp:genre", "nfo:genre");
        this.add_variable ("upnp:genre", SelectionQuery.ITEM_VARIABLE, "?_genre");

        this.add_key_chain ("sampleRate", "nfo:sampleRate");
        this.add_variable ("sampleRate", SelectionQuery.ITEM_VARIABLE, "?_rate");

        this.add_key_chain ("upnp:nrAudioChannels", "nfo:channels");
        this.add_variable ("upnp:nrAudioChannels", SelectionQuery.ITEM_VARIABLE, "?_channels");

        this.add_key_chain ("upnp:bitsPerSample", "nfo:bitsPerSample");
        this.add_variable ("upnp:bitsPerSample", SelectionQuery.ITEM_VARIABLE, "?_bps");

        this.add_key_chain ("upnp:bitrate", "nfo:averageBitrate");
        this.add_variable ("upnp:bitrate", SelectionQuery.ITEM_VARIABLE, "?_rate");

        // Picture & Video Items
        this.add_key_chain ("width", "nfo:width");
        this.add_variable ("width", SelectionQuery.ITEM_VARIABLE, "?_w");

        this.add_key_chain ("height", "nfo:height");
        this.add_variable ("height", SelectionQuery.ITEM_VARIABLE, "?_h");

        this.add_key_chain ("rygel:originalVolumeNumber",
                            "nmm:musicAlbumDisc",
                            "nmm:setNumber");
        this.add_variable ("rygel:originalVolumeNumber", SelectionQuery.ITEM_VARIABLE, "?_vol");
    }

    public new string @get (string property) {
        var variable = this.variables[property];
        var str = variable.base_variable;

        if (this.property_map.has_key (property)) {
            foreach (var key in this.property_map[property]) {
                str = key + "(" + str + ")";
            }
        } else if (this.functions.has_key (property)) {
            str = this.functions[property].printf (str);
        }

        return str; // + " AS " + variable.alias;
    }

    private void add_variable (string property, string base_item, string alias) {
        this.variables[property] = new QueryVariable(base_item, alias);
    }

    private void add_key_chain (string property, ...) {
        var key_chain = new ArrayList<string> ();

        var list = va_list ();
        string key = list.arg ();

        while (key != null) {
            key_chain.add (key);

            key = list.arg ();
        }

        this.property_map[property] = key_chain;
    }

    private void add_function (string property, string function) {
        this.functions[property] = function;
    }

    private void add_alternative (string property, ...) {
        var list = va_list ();

        var str = new StringBuilder ("tracker:coalesce(");

        string alternative = list.arg ();
        while (alternative != null) {
            if (alternative.has_prefix ("?")) {
                str.append (alternative);
            } else {
                str.append_printf ("%s(%%1$s),", alternative);
            }
            alternative = list.arg ();
        }

        str.truncate (str.len - 1);
        str.append (")");

        this.add_function (property, str.str);
    }
}
