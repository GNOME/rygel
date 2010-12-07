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
public class Rygel.Tracker.KeyChainMap : HashMap<string, ArrayList<string>> {
    private static KeyChainMap key_chain_map;

    public static KeyChainMap get_key_chain_map () {
        if (unlikely (key_chain_map == null)) {
            key_chain_map = new KeyChainMap ();
        }

        return key_chain_map;
    }

    private KeyChainMap () {
        // Item
        add_key_chain ("res", "nie:url");
        add_key_chain ("fileName", "nfo:fileName");
        add_key_chain ("dc:title", "nie:title");
        add_key_chain ("dlnaProfile", "nmm:dlnaProfile");
        add_key_chain ("mimeType", "nie:mimeType");
        add_key_chain ("res@size", "nfo:fileSize");
        add_key_chain ("date", "nie:contentCreated");

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

        foreach (var key in this[property]) {
            str = key + "(" + str + ")";
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

        this[property] = key_chain;
    }
}

