/*
 * Copyright (C) 2011 Jens Georg
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

internal errordomain Rygel.Mediathek.VideoItemError {
    XML_PARSE_ERROR,
    NETWORK_ERROR
}

internal class Rygel.Mediathek.VideoItemFactory : Object {
    private static VideoItemFactory instance;
    private AsxPlaylistParser playlist_parser;

    public static VideoItemFactory get_default () {
        if (instance == null) {
            instance = new VideoItemFactory ();
        }

        return instance;
    }

    public async VideoItem? create (MediaContainer parent,
                                    Xml.Node      *xml_item)
                                    throws VideoItemError {
        string title;
        string playlist_url;
        this.extract_data_from_xml (xml_item,
                                    out title,
                                    out playlist_url);

        var resolved_uris = yield playlist_parser.parse (playlist_url);

        if (resolved_uris == null || resolved_uris.size == 0) {
            return null;
        }

        var id = Checksum.compute_for_string (ChecksumType.MD5, title);
        var item = new VideoItem (id, parent, title);

        item.mime_type = "video/x-ms-wmv";
        item.author = "ZDF - Second German TV Channel Streams";

        foreach (var uri in resolved_uris) {
            item.add_uri (uri);
        }

        return item;
    }

    private VideoItemFactory () {
        playlist_parser = new AsxPlaylistParser
                                        (RootContainer.get_default_session ());
    }

    private bool namespace_ok (Xml.Node* node) {
        return node->ns != null && node->ns->prefix == "media";
    }

    private void extract_data_from_xml (Xml.Node   *item,
                                        out string  title,
                                        out string  playlist_url)
                                        throws VideoItemError {
        var title_node = XMLUtils.get_element (item, "title");
        var group = XMLUtils.get_element (item, "group");

        if (title_node == null) {
            throw new VideoItemError.XML_PARSE_ERROR ("No 'title' element");
        }

        if (group == null) {
            throw new VideoItemError.XML_PARSE_ERROR ("No 'group' element");
        }

        if (!namespace_ok (group)) {
            throw new VideoItemError.XML_PARSE_ERROR ("Invalid namespace");
        }

        var content = XMLUtils.get_element (group, "content");
        if (content == null) {
            throw new VideoItemError.XML_PARSE_ERROR
                                        ("'group' has no 'content' element");
        }

        // content points to the first content subnode now
        while (content != null) {
            var url_attribute = content->has_prop ("url");
            if (url_attribute != null && namespace_ok (content)) {
                
                unowned string url = url_attribute->children->content;
                if (url.has_suffix (".asx")) {
                    playlist_url = url;

                    break;
                }

            }
            content = content->next;
        }

        if (playlist_url == null) {
            throw new VideoItemError.XML_PARSE_ERROR ("No URL found");
        }

        title = title_node->get_content ();
    }
}
