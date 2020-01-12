/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;
using Gee;

/**
 * An interface representing visual properties of an item stored in a file.
 */
public interface Rygel.VisualItem : MediaFileItem {

    /**
     * The width of the source content (this.uri) in pixels.
     * A value of -1 means that the width is unknown
     */
    public abstract int width { get; set; }

    /**
     * The height of the source content (this.uri) in pixels.
     * A value of -1 means that the height is unknown
     */
    public abstract int height { get; set; }

    /**
     * The number of bits per pixel in the video or image resource (this.uri).
     * A value of -1 means that the color depth is unknown
     */
    public abstract int color_depth { get; set; }

    /**
     * Thumbnail pictures to represent the video or image resource.
     */
    public abstract ArrayList<Thumbnail> thumbnails { get; protected set; }

    internal void add_thumbnail_for_uri (string uri) {
        // Lets see if we can provide the thumbnails
        var thumbnailer = Thumbnailer.get_default ();

        if (thumbnailer != null && this.mime_type != null) {
            try {
                var thumb = thumbnailer.get_thumbnail (uri, this.mime_type);
                this.thumbnails.add (thumb);
            } catch (Error err) {
                debug ("Failed to get thumbnail: %s", err.message);
            }
        }
    }

    internal void set_visual_resource_properties (MediaResource res) {
        res.width = this.width;
        res.height = this.height;
        res.color_depth = this.color_depth;
    }

    internal void add_thumbnail_resources (HTTPServer http_server) {
        if (this.place_holder) {
            return;
        }

        for (var i = 0; i < this.thumbnails.size; i++) {
            var thumbnail = this.thumbnails.get (i);
            // Add the defined thumbnail uri unconditionally
            //  (it will be filtered out if the request is remote)
            string protocol;
            try {
                protocol = this.get_protocol_for_uri (thumbnail.uri);
            } catch (Error e) {
                message (/*_*/("Could not determine protocol for URI %s"),
                         thumbnail.uri);

                continue;
            }

            var thumb_res = thumbnail.get_resource (protocol, i);
            thumb_res.uri = thumbnail.uri;
            this.get_resource_list ().add (thumb_res);
            if (http_server.need_proxy (thumbnail.uri)) {
                var http_thumb_res = thumbnail.get_resource
                                    (http_server.get_protocol (), i);

                var index = this.thumbnails.index_of (thumbnail);
                // Make a http uri for the thumbnail
                http_thumb_res.uri = http_server.create_uri_for_object
                                             (this,
                                              index,
                                              -1,
                                              null);
                this.get_resource_list ().add (http_thumb_res);
            }
        }
    }
}
