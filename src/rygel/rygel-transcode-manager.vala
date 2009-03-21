/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
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

using Rygel;
using GUPnP;
using Gee;
using Gst;

public abstract class Rygel.TranscodeManager : GLib.Object {
    internal abstract string create_uri_for_item
                                            (MediaItem  item,
                                             string?    transcode_target,
                                             out string protocol);

    internal virtual void add_resources (ArrayList<DIDLLiteResource?> resources,
                                         MediaItem                    item)
                                         throws Error {
        string mime_type;

        if (item.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            // No  transcoding for images yet :(
            return;
        } else if (item.upnp_class.has_prefix (MediaItem.MUSIC_CLASS)) {
            mime_type = "audio/mpeg";
        } else {
            mime_type = "video/mpeg";
        }

        if (item.mime_type == mime_type) {
            return;
        }

        string protocol;
        var uri = this.create_uri_for_item (item, mime_type, out protocol);
        DIDLLiteResource res = item.create_res (uri);
        res.mime_type = mime_type;
        res.protocol = protocol;
        res.dlna_conversion = DLNAConversion.TRANSCODED;
        res.dlna_flags = DLNAFlags.STREAMING_TRANSFER_MODE;
        res.dlna_operation = DLNAOperation.NONE;
        res.size = -1;

        resources.add (res);
    }

    internal Element get_transcoding_src (Element src,
                                          string  target)
                                          throws Error {
        if (target == "audio/mpeg") {
            return new MP2Transcoder (src);
        } else if (target == "video/mpeg") {
            return new MP2TSTranscoder (src);
        } else {
            throw new HTTPRequestError.NOT_FOUND (
                            "No transcoder available for target format '%s'",
                            target);
        }
    }
}

