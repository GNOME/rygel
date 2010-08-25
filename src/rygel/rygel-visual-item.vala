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
 * An interface that visual (video and image) items must implement.
 */
public interface Rygel.VisualItem : MediaItem {
    public abstract int width { get; set; }
    public abstract int height { get; set; }
    public abstract int pixel_width { get; set; }
    public abstract int pixel_height { get; set; }
    public abstract int color_depth { get; set; }

    public abstract ArrayList<Thumbnail> thumbnails { get; protected set; }

    internal void add_thumbnail_for_uri (string uri) {
        // Lets see if we can provide the thumbnails
        var thumbnailer = Thumbnailer.get_default ();

        if (thumbnailer != null) {
            try {
                var thumb = thumbnailer.get_thumbnail (uri);
                this.thumbnails.add (thumb);
            } catch (Error err) {}
        }
    }

    internal void add_thumbnail_resources (DIDLLiteItem didl_item,
                                           bool         allow_internal)
                                           throws Error {
        foreach (var thumbnail in this.thumbnails) {
            var protocol = this.get_protocol_for_uri (thumbnail.uri);

            if (allow_internal || protocol != "internal") {
                thumbnail.add_resource (didl_item, protocol);
            }
        }
    }

    internal void add_visual_props (DIDLLiteResource res) {
        res.width = this.width;
        res.height = this.height;
        res.color_depth = this.color_depth;
    }

    internal void add_thumbnail_proxy_resources (HTTPServer   server,
                                                 DIDLLiteItem didl_item)
                                                 throws Error {
        foreach (var thumbnail in this.thumbnails) {
            if (server.need_proxy (thumbnail.uri)) {
                var uri = thumbnail.uri; // Save the original URI
                var index = this.thumbnails.index_of (thumbnail);

                thumbnail.uri = server.create_uri_for_item (this,
                                                            index,
                                                            -1,
                                                            null);
                thumbnail.add_resource (didl_item, server.get_protocol ());

                // Now restore the original URI
                thumbnail.uri = uri;
            }
        }
    }
}
