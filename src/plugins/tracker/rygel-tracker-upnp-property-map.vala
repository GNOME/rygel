/*
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2012 Jens Georg <mail@jensge.org>
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
 * A map of UPnP properties to tracker property functions, coalesces,
 * subqueries or other custom functions
 */
public class Rygel.Tracker.UPnPPropertyMap : Object {
    HashMap<string, ArrayList<string>> property_map;
    HashMap<string, string> functions;
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

        // Item
        this.add_key_chain ("res", "nie:url");
        this.add_function ("place_holder",
                      "tracker:coalesce((SELECT false WHERE { { %s a ?o } " +
                      "FILTER (?o IN (nfo:FileDataObject, " +
                      "nfo:RemoteDataObject)) }), true)");
        this.add_key_chain ("fileName", "nfo:fileName");
        this.add_alternative ("dc:title", "nie:title", "nfo:fileName");
        this.add_key_chain ("dlnaProfile", "nmm:dlnaProfile");
        this.add_alternative ("mimeType", "nmm:dlnaMime", "nie:mimeType");
        this.add_alternative ("res@size", "nfo:fileSize", "nie:byteSize");
        this.add_alternative ("date",
                              "nie:contentCreated",
                              "nfo:fileLastModified");

        // Music Item
        this.add_key_chain ("res@duration", "nfo:duration");
        this.add_key_chain ("upnp:artist", "nmm:performer", "nmm:artistName");
        this.add_key_chain ("dc:creator", "nmm:performer", "nmm:artistName");
        this.add_key_chain ("upnp:album", "nmm:musicAlbum", "nmm:albumTitle");
        this.add_key_chain ("upnp:originalTrackNumber", "nmm:trackNumber");
        this.add_key_chain ("upnp:genre", "nfo:genre");
        this.add_key_chain ("sampleRate", "nfo:sampleRate");
        this.add_key_chain ("upnp:nrAudioChannels", "nfo:channels");
        this.add_key_chain ("upnp:bitsPerSample", "nfo:bitsPerSample");
        this.add_key_chain ("upnp:bitrate", "nfo:averageBitrate");

        // Picture & Video Items
        this.add_key_chain ("width", "nfo:width");
        this.add_key_chain ("height", "nfo:height");

        this.add_key_chain ("rygel:originalVolumeNumber",
                            "nmm:musicAlbumDisc",
                            "nmm:setNumber");
    }

    public new string @get (string property) {
        var str = SelectionQuery.ITEM_VARIABLE;

        if (this.property_map.has_key (property)) {
            foreach (var key in this.property_map[property]) {
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
            str.append_printf ("%s(%%1$s),", alternative);
            alternative = list.arg ();
        }

        str.truncate (str.len - 1);
        str.append (")");

        this.add_function (property, str.str);
    }
}
