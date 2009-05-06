/*
 * Copyright (C) 2009 Jens Georg
 *
 * Author: Jens Georg <mail@jensge.org>
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

using GLib;
using Gee;
using Soup;
using Xml;

public errordomain Rygel.MediathekAsxPlaylistError {
    XML_ERROR,
    NETWORK_ERROR
}

/**
 * This class is a simple ASX playlist parser
 * 
 * It does nothing but extracting all href tags from an ASX
 * and ignore all of the other information that may be in it
 * 
 * This parser is //only// intended to work with the simple 
 * ASX files presented by the ZDF Mediathek streaming server
 */
public class Rygel.MediathekAsxPlaylist : Object {
    public ArrayList<string> uris;
    private string uri;

    public MediathekAsxPlaylist (string uri) {
        this.uris = new ArrayList<string> ();
        this.uri = uri;
    }

    /** 
     * Get and parse the ASX file.
     *
     * This will fetch the ASX file represented by an uri
     * using a synchronous soup session. As ASX seems to be
     * a bit inconsistent wrt tag case all the tags are
     * converted to lowercase. A XPath query is then used
     * to extract all of the href attributes for every entry
     * in the file
     */
    public void parse() throws MediathekAsxPlaylistError {
        // FIXME make async using global soup session
        var session = new Soup.SessionSync ();
        var message = new Soup.Message ("GET",
                                        this.uri);

        session.send_message (message);
        if (message.status_code == 200) {
            try {
                // lowercase all tags using regex and \L\E syntax
                var normalizer = new Regex ("(<[/]?)([a-zA-Z:]+)");
                string normalized_content = 
                        normalizer.replace (message.response_body.data,
                                            (long)message.response_body.length,
                                            0, 
                                            "\\1\\L\\2\\E");

                var doc = Parser.parse_memory (normalized_content, 
                                               (int)normalized_content.length);

                if (doc != null) {
                    var ctx = new XPathContext (doc);
                    var xpo = ctx.eval ("/asx/entry/ref/@href");
                    if (xpo->type == XPathObjectType.NODESET) {
                        for (int i = 0; i < xpo->nodesetval->length (); i++) {
                            var item = xpo->nodesetval->item (i);
                            uris.add (item->children->content);
                        }
                    }
                }
                else {
                    throw new 
                        MediathekAsxPlaylistError.XML_ERROR (
                                                  "Could not received XML");
                }
            }
            catch (RegexError error) { }
        }
        else {
            throw new MediathekAsxPlaylistError.NETWORK_ERROR (
                 "Could not download playlist, error code was %u (%s)".printf (
                 message.status_code, 
                 Soup.status_get_phrase (message.status_code)));
        }
    }
}
