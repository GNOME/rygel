/*
 * Copyright (C) 2009-2011 Jens Georg
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

using Gee;
using Soup;
using Xml;

/**
 * This class is a simple ASX playlist parser
 *
 * It does nothing but extracting all href tags from an ASX
 * and ignore all of the other information that may be in it
 *
 * This parser is //only// intended to work with the simple
 * ASX files presented by the ZDF Mediathek streaming server
 */
internal class Rygel.Mediathek.AsxPlaylistParser : PlaylistParser {
    private Regex normalizer;

    public AsxPlaylistParser (Session session) {
        Object (session         : session,
                playlist_suffix : ".asx",
                mime_type       : "video/x-ms-wmv");
        try {
            this.normalizer = new Regex ("(<[/]?)([a-zA-Z:]+)");
        } catch (RegexError error) {};
    }

    /**
     * Get and parse the ASX file.
     *
     * This will fetch the ASX file using the soup session configured on
     * configure time.As ASX seems to be a bit inconsistent with regard to tag
     * case, all the tags are converted to lowercase. A XPath query is then used
     * to extract all of the href attributes for every entry in the file.
     *
     * @param uri network location of the ASX file
     * @return a list of uris found in this file
     */
    public override Gee.List<string>? parse_playlist (string data,
                                                      int length)
                                                      throws VideoItemError {
        ArrayList<string> uris = null;

        try {
            // lowercase all tags using regex and \L\E syntax
            var normalized_content = this.normalizer.replace
                                        (data,
                                         length,
                                         0,
                                         "\\1\\L\\2\\E");

            var doc = Parser.parse_memory (normalized_content,
                                           (int) normalized_content.length);
            if (doc == null) {
                throw new VideoItemError.XML_PARSE_ERROR
                                        ("Could not parse playlist");
            }

            var doc_guard = new GUPnP.XMLDoc (doc);
            var context = new XPath.Context (doc_guard.doc);

            var xpath_object = context.eval ("/asx/entry/ref/@href");

            if (xpath_object->type != XPath.ObjectType.NODESET) {
                xpath_free_object (xpath_object);
                throw new VideoItemError.XML_PARSE_ERROR
                                        ("No uris found in playlist");
            }

            uris = new ArrayList<string> ();
            for (int i = 0;
                 i < xpath_object->nodesetval->length ();
                 i++) {
                var item = xpath_object->nodesetval->item (i);
                uris.add (item->children->content);
            }

            xpath_free_object (xpath_object);
        } catch (RegexError error) {
            throw new VideoItemError.XML_PARSE_ERROR ("Failed to normalize");
        }

        return uris;
    }
}
