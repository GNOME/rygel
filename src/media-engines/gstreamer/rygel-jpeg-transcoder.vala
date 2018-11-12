/*
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2018 Jens Georg <mail@jensge.org>
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Jens Georg <mail@jensge.org>
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

using Gst;
using Gst.PbUtils;
using GUPnP;

internal class Rygel.JPEGTranscoder : Rygel.GstTranscoder {
    private const string PROFILE_TEMPLATE =
        "image/jpeg,framerate=(fraction)1/1,width=%d,height=%d";

    public JPEGTranscoder () {
        base ("JPEG_SM",
              "image/jpeg",
              "JPEG_SM",
              "jpg");
    }

    private void calculate_dimensions (VisualItem item, out int width, out int height) {
        if (item.width <= 640 && item.height <= 480) {
            width = item.width;
            height = item.height;

            return;
        }

        width = 640;
        height = 480;

        if (item.width > 0 && item.height > 0) {
            var dar = (float) item.width / (float) item.height;
            if (dar > 4.0/3.0) {
                height = (int) Math.lrint (640.0 / dar);
            } else {
                width = (int) Math.lrint (480.0 * dar);
            }
        }
    }

    protected override EncodingProfile get_encoding_profile
                                        (MediaFileItem file_item) {
        var item = file_item as VisualItem;
        int width = -1;
        int height = -1;

        this.calculate_dimensions (item, out width, out height);

        var caps = Caps.from_string (PROFILE_TEMPLATE.printf (width, height));
        var profile = new EncodingVideoProfile (caps, null, null, 1);

        return profile;

    }

    public override uint get_distance (MediaFileItem item) {
        debug ("Getting distance of JPEG transcoder to %s", item.id);

        if (!(item is ImageItem)) {
            debug ("%s is not an image, skipping", item.id);

            return uint.MAX;
        }

        if (item is VideoItem) {
            debug ("%s is a VideoItem, skipping", item.id);

            return uint.MAX;
        }

        if (item.dlna_profile == "JPEG_SM") {
            debug ("%s is already JPEG_SM, skipping", item.id);

            return uint.MAX;
        }

        return 1;
    }

    public override MediaResource? get_resource_for_item (MediaFileItem item) {
        var resource = base.get_resource_for_item (item);

        // Override Seeking, you cannot really time-seek an image
        resource.dlna_operation = DLNAOperation.NONE;

        // Images must be INTERACTIVE_TRANSFER_MODE
        resource.dlna_flags &= ~DLNAFlags.STREAMING_TRANSFER_MODE;
        resource.dlna_flags |= DLNAFlags.INTERACTIVE_TRANSFER_MODE;

        int width;
        int height;
        this.calculate_dimensions (item as VisualItem, out width, out height);
        resource.width = width;
        resource.height = height;

        return resource;
    }
}
