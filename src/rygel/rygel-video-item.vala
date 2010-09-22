/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using GUPnP;
using Gee;
using Gst;

/**
 * Represents a video item.
 */
public class Rygel.VideoItem : AudioItem, VisualItem {
    public new const string UPNP_CLASS = "object.item.videoItem";

    public string author;

    public int width { get; set; default = -1; }
    public int height { get; set; default = -1; }
    public int pixel_width { get; set; default = -1; }
    public int pixel_height { get; set; default = -1; }
    public int color_depth { get; set; default = -1; }

    public ArrayList<Thumbnail> thumbnails { get; protected set; }
    public ArrayList<Subtitle> subtitles;

    public VideoItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = VideoItem.UPNP_CLASS) {
        base (id, parent, title, upnp_class);

        this.thumbnails = new ArrayList<Thumbnail> ();
        this.subtitles = new ArrayList<Subtitle> ();
    }

    public override bool streamable () {
        return true;
    }

    public override void add_uri (string uri) {
        base.add_uri (uri);

        this.add_thumbnail_for_uri (uri);

        var subtitle_manager = SubtitleManager.get_default ();

        if (subtitle_manager != null) {
            try {
                var subtitle = subtitle_manager.get_subtitle (uri);
                this.subtitles.add (subtitle);
            } catch (Error err) {}
        }
    }

    internal override void add_resources (DIDLLiteItem didl_item,
                                          bool         allow_internal)
                                          throws Error {
        foreach (var subtitle in this.subtitles) {
            var protocol = this.get_protocol_for_uri (subtitle.uri);

            if (allow_internal || protocol != "internal") {
                subtitle.add_didl_node (didl_item);
            }
        }

        base.add_resources (didl_item, allow_internal);

        add_thumbnail_resources (didl_item, allow_internal);
    }

    internal override DIDLLiteResource add_resource (
                                        DIDLLiteItem didl_item,
                                        string?      uri,
                                        string       protocol,
                                        string?      import_uri = null)
                                        throws Error {
        var res = base.add_resource (didl_item, uri, protocol, import_uri);

        this.add_visual_props (res);

        return res;
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        if (!(media_object is VideoItem)) {
           return 1;
        }

        var item = media_object as VideoItem;

        switch (property) {
        case "dc:author":
            return this.compare_string_props (this.author, item.author);
        default:
            return base.compare_by_property (item, property);
        }
    }

    internal override DIDLLiteObject serialize (DIDLLiteWriter writer,
                                                HTTPServer     http_server)
                                                throws Error {
        var didl_item = base.serialize (writer, http_server);

        if (this.author != null && this.author != "") {
            var contributor = didl_item.add_author ();
            contributor.name = this.author;
        }

        return didl_item;
    }

    internal override void add_proxy_resources (HTTPServer   server,
                                                DIDLLiteItem didl_item)
                                                throws Error {
        if (!this.place_holder) {
            // Subtitles first
            foreach (var subtitle in this.subtitles) {
                if (!server.need_proxy (subtitle.uri)) {
                    continue;
                }

                var uri = subtitle.uri; // Save the original URI
                var index = this.subtitles.index_of (subtitle);

                subtitle.uri = server.create_uri_for_item (this,
                                                           -1,
                                                           index,
                                                           null);
                subtitle.add_didl_node (didl_item);

                // Now restore the original URI
                subtitle.uri = uri;
            }
        }

        base.add_proxy_resources (server, didl_item);

        if (!this.place_holder) {
            // Thumbnails comes in the end
            this.add_thumbnail_proxy_resources (server, didl_item);
        }
    }
}
