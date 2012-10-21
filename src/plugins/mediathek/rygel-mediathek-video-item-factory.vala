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

internal class Rygel.Mediathek.VideoItem : Rygel.TrackableItem,
                                           Rygel.VideoItem {
    public VideoItem (string id, MediaContainer parent, string title) {
        base (id, parent, title);
    }
}

internal class Rygel.Mediathek.VideoItemFactory : Object {
    private static VideoItemFactory instance;
    private PlaylistParser playlist_parser;
    private const string VIDEO_FORMAT_WMV = "wmv";
    private const string VIDEO_FORMAT_MP4 = "mp4";
    private string video_format;

    public static VideoItemFactory get_default () {
        if (instance == null) {
            instance = new VideoItemFactory ();
        }

        return instance;
    }

    public async VideoItem? create (MediaContainer parent,
                                    Xml.Node      *xml_item)
                                    throws VideoItemError {
        string title, playlist_url, date, description = null;

        this.extract_data_from_xml (xml_item,
                                    out title,
                                    out playlist_url,
                                    out date,
                                    out description);

        var resolved_uris = yield playlist_parser.parse (playlist_url);

        if (resolved_uris == null || resolved_uris.size == 0) {
            return null;
        }

        var id = Checksum.compute_for_string (ChecksumType.MD5, title);
        var item = new VideoItem (id, parent, title);

        item.mime_type = this.playlist_parser.mime_type;
        item.author = "ZDF - Second German TV Channel Streams";
        item.date = date;
        item.description = description;

        if (this.video_format == VIDEO_FORMAT_WMV) {
            item.dlna_profile = "WMVMED_FULL";
        }

        foreach (var uri in resolved_uris) {
            item.add_uri (uri);
        }

        return item;
    }

    private VideoItemFactory () {
        var config = Rygel.MetaConfig.get_default ();
        this.video_format = VIDEO_FORMAT_WMV;

        try {
            this.video_format = config.get_string ("ZDFMediathek",
                                                   "video-format");
            this.video_format = this.video_format.casefold ();
            if (this.video_format != VIDEO_FORMAT_WMV &&
                this.video_format != VIDEO_FORMAT_MP4) {
                this.video_format = VIDEO_FORMAT_WMV;
            }
        } catch (Error error) { }

        debug ("Exposing mediathek items in format: %s", video_format);
        var session = RootContainer.get_default_session ();

        switch (video_format) {
            case VIDEO_FORMAT_WMV:
                this.playlist_parser = new AsxPlaylistParser (session);
                break;
            case VIDEO_FORMAT_MP4:
                this.playlist_parser = new MovPlaylistParser (session);
                break;
            default:
                assert_not_reached ();
        }
    }

    private bool namespace_ok (Xml.Node* node, string prefix = "media") {
        return node->ns != null && node->ns->prefix == prefix;
    }

    private void extract_data_from_xml (Xml.Node   *item,
                                        out string  title,
                                        out string  playlist_url,
                                        out string? date,
                                        out string? description)
                                        throws VideoItemError {
        var title_node = XMLUtils.get_element (item, "title");
        var group = XMLUtils.get_element (item, "group");
        playlist_url = null;

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
                if (url.has_suffix (this.playlist_parser.playlist_suffix)) {
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

        var date_node = XMLUtils.get_element (item, "date");
        if (date_node != null && this.namespace_ok (date_node, "dc")) {
            date = date_node->get_content ();
        } else {
            date = null;
        }

        var desc_node = XMLUtils.get_element (item, "description");
        if (desc_node != null) {
            description = desc_node->get_content ();
        } else {
            description = null;
        }
    }
}
