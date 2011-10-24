/*
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Author: Sunil Mohan Adapa <sunil@medhas.org>
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
 * A map of upnp properties to tracker property key chains
 */
public class Rygel.Tracker.KeyChainMap : Object {
    HashMap<string, ArrayList<string>> key_chain_map;
    HashMap<string, string> functions;
    private static KeyChainMap instance;

    public static KeyChainMap get_key_chain_map () {
        if (unlikely (instance == null)) {
            instance = new KeyChainMap ();
        }

        return instance;
    }

    private KeyChainMap () {
        this.key_chain_map = new HashMap<string, ArrayList<string>> ();
        this.functions = new HashMap<string, string> ();

        // Item
        add_key_chain ("res", "nie:url");
        add_function ("place_holder",
                      "tracker:coalesce((SELECT false WHERE { { %s a ?o } " +
                      "FILTER (?o IN (nfo:FileDataObject, " +
                      "nfo:RemoteDataObject)) }), true)");
        add_key_chain ("fileName", "nfo:fileName");
        add_key_chain ("dc:title", "nie:title");
        add_key_chain ("dlnaProfile", "nmm:dlnaProfile");
        add_key_chain ("mimeType", "nie:mimeType");
        add_function ("res@size",
                      "tracker:coalesce(nfo:fileSize(%1$s)," +
                      "nie:byteSize(%1$s),\"\")");
        add_function ("date",
                      "tracker:coalesce(nie:contentCreated(%1$s)," +
                      "nfo:fileLastModified(%1$s))");

        // Music Item
        add_key_chain ("res@duration", "nfo:duration");
        add_key_chain ("upnp:artist", "nmm:performer", "nmm:artistName");
        add_key_chain ("dc:creator", "nmm:performer", "nmm:artistName");
        add_key_chain ("upnp:album", "nmm:musicAlbum", "nmm:albumTitle");
        add_key_chain ("upnp:originalTrackNumber", "nmm:trackNumber");
        add_key_chain ("upnp:genre", "nfo:genre");
        add_key_chain ("sampleRate", "nfo:sampleRate");
        add_key_chain ("upnp:nrAudioChannels", "nfo:channels");
        add_key_chain ("upnp:bitsPerSample", "nfo:bitsPerSample");
        add_key_chain ("upnp:bitrate", "nfo:averageBitrate");

        // Picture & Video Items
        add_key_chain ("width", "nfo:width");
        add_key_chain ("height", "nfo:height");
    }

    public string map_property (string property) {
        var str = SelectionQuery.ITEM_VARIABLE;

        if (this.key_chain_map.has_key (property)) {
            foreach (var key in this.key_chain_map[property]) {
                str = key + "(" + str + ")";
            }
        } else if (this.functions.has_key (property)) {
            str = this.functions[property].printf (str);
        }

        return str;
    }

    private void add_key_chain (string property, ...) {
        var key_chain = new ArrayList<string> ();

        var list = va_list ();
        string key = list.arg ();

        while (key != null) {
            key_chain.add (key);

            key = list.arg ();
        }

        this.key_chain_map[property] = key_chain;
    }

    private void add_function (string property, string function) {
        this.functions[property] = function;
    }
}

