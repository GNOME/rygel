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

internal class Rygel.HTTPSubtitleHandler : Rygel.HTTPGetHandler {
    private MediaFileItem media_item;
    private int subtitle_index;
    public Subtitle subtitle;

    public HTTPSubtitleHandler (MediaFileItem media_item,
                                int subtitle_index,
                                Cancellable? cancellable)
                                throws HTTPRequestError {
        this.media_item = media_item;
        this.subtitle_index = subtitle_index;
        this.cancellable = cancellable;

        if (subtitle_index >= 0 && media_item is VideoItem) {
            var video_item = media_item as VideoItem;

            if (subtitle_index < video_item.subtitles.size) {
                this.subtitle = video_item.subtitles.get (subtitle_index);
            }
        }

        if (this.subtitle == null) {
            var msg = /*_*/("Subtitle index %d not found for item '%s");
            throw new HTTPRequestError.NOT_FOUND (msg,
                                                  subtitle_index,
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
                                             subtitle.mime_type);

        // Add contentFeatures.dlna.org

        // This is functionally equivalent to how contentFeatures was formed
        // via the (deprecated) HTTPIdentityHandler
        var res = this.media_item.get_resource_list ().get (0);
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
            src = engine.create_data_source_for_uri (this.subtitle.uri);

            return new HTTPResponse (request, this, src);
        } catch (Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    public override int64 get_resource_size () {
        return subtitle.size;
    }

    public override bool supports_byte_seek () {
        return true;
    }
}
