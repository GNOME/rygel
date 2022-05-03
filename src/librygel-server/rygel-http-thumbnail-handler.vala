/*
 * Copyright (C) 2008, 2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
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

internal class Rygel.HTTPThumbnailHandler : Rygel.HTTPGetHandler {
    private MediaFileItem media_item;
    private int thumbnail_index;
    private Thumbnail thumbnail;

    public HTTPThumbnailHandler (MediaFileItem media_item,
                                 int thumbnail_index,
                                 Cancellable? cancellable)
                                 throws HTTPRequestError {

        this.media_item = media_item;
        this.thumbnail_index = thumbnail_index;
        this.cancellable = cancellable;

        if (media_item is MusicItem) {
            var music_item = media_item as MusicItem;
            this.thumbnail = music_item.album_art;
        } else if (media_item is VisualItem) {
            var visual_item = media_item as VisualItem;
            if (thumbnail_index < visual_item.thumbnails.size) {
                this.thumbnail = visual_item.thumbnails.get (thumbnail_index);
            }
        }

        if (this.thumbnail == null) {
            var msg = ("Thumbnail index %d not found for item '%s");
            throw new HTTPRequestError.NOT_FOUND (msg,
                                                  thumbnail_index,
                                                  media_item.id);
        }
    }

    public override bool supports_transfer_mode (string mode) {
        // Support interactive and background transfers only
        return (mode != TRANSFER_MODE_STREAMING);
    }

    public override void add_response_headers (HTTPGet request)
                                               throws HTTPRequestError {
        // Add Content-Type
        request.msg.get_response_headers ().append ("Content-Type",
                                             thumbnail.mime_type);

        // Add contentFeatures.dlna.org
        var res = this.thumbnail.get_resource
                                        (request.http_server.get_protocol (),
                                         this.thumbnail_index);
        var protocol_info = res.get_protocol_info ().to_string ();
        var pi_fields = protocol_info.split (":", 4);
        request.msg.get_response_headers ().append ("contentFeatures.dlna.org",
                                             pi_fields[3]);

        // Chain-up
        base.add_response_headers (request);
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        DataSource src;
        try {
            var engine = MediaEngine.get_default ();
            src = engine.create_data_source_for_uri (this.thumbnail.uri);

            return new HTTPResponse (request, this, src);
        } catch (Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    public override int64 get_resource_size () {
        return thumbnail.size;
    }

    public override bool supports_byte_seek () {
        return true;
    }
}
