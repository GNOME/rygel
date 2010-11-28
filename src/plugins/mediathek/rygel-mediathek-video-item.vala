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
using Xml;

public errordomain Rygel.Mediathek.VideoItemError {
    XML_PARSE_ERROR
}

public class Rygel.Mediathek.VideoItem : Rygel.VideoItem {
    private VideoItem (MediaContainer parent, string title) {
        base (Checksum.compute_for_string (ChecksumType.MD5, title),
              parent,
              title);

        this.mime_type = "video/x-ms-wmv";
        this.author = "ZDF - Second German TV Channel Streams";
    }

    private static bool namespace_ok(Xml.Node* node) {
        return node->ns != null && node->ns->prefix == "media";
    }

    public static AsxPlaylist? handle_content (Xml.Node *group)
                                               throws VideoItemError {
        AsxPlaylist asx = null;
        if (namespace_ok (group)) {
            Xml.Attr* attr = group->has_prop ("url");
            if (attr != null) {
                var url = attr->children->content;
                if (url.has_suffix (".asx")) {
                    try {
                        asx = new AsxPlaylist (url);
                        asx.parse ();
                    } catch (AsxPlaylistError error) {
                        asx = null;
                    }
                }
            }
            else {
                throw new VideoItemError.XML_PARSE_ERROR
                                        ("group node has no 'url' property");
            }
        }
        else {
            throw new VideoItemError.XML_PARSE_ERROR
                                        ("invalid or no namespace");
        }

        return asx;
    }

    public static VideoItem create_from_xml (MediaContainer parent,
                                             Xml.Node      *item)
                                             throws VideoItemError {
        string title = null;
        VideoItem video_item = null;
        AsxPlaylist asx = null;

        for (Xml.Node* item_child = item->children; 
             item_child != null; 
             item_child = item_child->next)
        {
            switch (item_child->name) {
                case "title":
                    title = item_child->get_content ();
                    break;
                case "group":
                    if (namespace_ok (item_child)) {
                        for (Xml.Node* group = item_child->children; 
                             group != null;
                             group = group->next) {
                            if (group->name == "content") {
                                asx = handle_content (group);
                            }
                        }
                    }
                    else {
                        var msg = "Invalid or no namespace on group node";

                        throw new VideoItemError.XML_PARSE_ERROR (msg);
                    }
                    break;
                default:
                    break;
             }

        }
        if (title == null) {
            throw new VideoItemError.XML_PARSE_ERROR
                                        ("Could not find title");
        }


        if (asx == null) {
            throw new VideoItemError.XML_PARSE_ERROR
                                        ("Could not find URIs");
        }

        video_item = new VideoItem (parent, title);
        foreach (string uri in asx.uris) {
            video_item.add_uri (uri);
        }

        return video_item;
    }
}
