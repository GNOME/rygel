/*
 * Copyright (C) 2009 Nokia Corporation.
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
using Gst;
using GUPnP;
using Gee;

/**
 * The base Transcoder class. Each implementation derives from it and must
 * at least implement create_source method.
 */
internal abstract class Rygel.Transcoder : GLib.Object, HTTPRequestHandler {
    public string mime_type { get; protected set; }
    public string dlna_profile { get; protected set; }

    // Primary UPnP item class that this transcoder is meant for, doesn't
    // necessarily mean it cant be used for other classes.
    public string upnp_class { get; protected set; }

    public Transcoder (string mime_type,
                       string dlna_profile,
                       string upnp_class) {
        this.mime_type = mime_type;
        this.dlna_profile = dlna_profile;
        this.upnp_class = upnp_class;
    }

    /**
     * Creates a transcoding source.
     *
     * @param src the media item to create the transcoding source for
     * @param src the original (non-transcoding) source
     *
     * @return      the new transcoding source
     */
    public abstract Element create_source (MediaItem item,
                                           Element   src) throws Error;

    public virtual DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                   MediaItem        item,
                                                   TranscodeManager manager)
                                                   throws Error {
        if (this.mime_type_is_a (item.mime_type, this.mime_type)) {
            return null;
        }

        string protocol;
        var uri = manager.create_uri_for_item (item,
                                               this.dlna_profile,
                                               out protocol);
        var res = item.add_resource (didl_item, uri, protocol);
        res.size = -1;

        var protocol_info = res.protocol_info;
        protocol_info.mime_type = this.mime_type;
        protocol_info.dlna_profile = this.dlna_profile;
        protocol_info.dlna_conversion = DLNAConversion.TRANSCODED;
        protocol_info.dlna_flags = DLNAFlags.STREAMING_TRANSFER_MODE;
        protocol_info.dlna_operation = DLNAOperation.TIMESEEK;

        return res;
    }

    public bool can_handle (string target) {
        return target == this.dlna_profile;
    }

    /**
     * Gets the numeric value that gives an gives an estimate of how hard
     * would it be to trancode @item to target profile of this transcoder.
     *
     * @param item the media item to calculate the distance for
     *
     * @return      the distance from the @item, uint.MIN if providing such a
     *              value is impossible or uint.MAX if it doesn't make any
     *              sense to use this transcoder for @item
     */
    public abstract uint get_distance (MediaItem item);

    protected bool mime_type_is_a (string mime_type1, string mime_type2) {
        string content_type1 = g_content_type_from_mime_type (mime_type1);
        string content_type2 = g_content_type_from_mime_type (mime_type2);

        return g_content_type_is_a (content_type1, content_type2);
    }

    public virtual void add_response_headers (HTTPRequest request)
            throws HTTPRequestError {
        request.msg.response_headers.append ("Content-Type", this.mime_type);
        if (request.time_range != null) {
            request.time_range.add_response_header(request.msg);
        }
    }

    public virtual HTTPResponse render_body (HTTPRequest request)
            throws HTTPRequestError {
        weak MediaItem item = request.item;
        Element src = item.create_stream_source ();

        if (src == null) {
            throw new HTTPRequestError.NOT_FOUND ("Not found");
        }

        src = this.create_source (item, src);
        return new LiveResponse (request.server,
                                 request.msg,
                                 "RygelLiveResponse",
                                 src,
                                 request.time_range);
    }
}

