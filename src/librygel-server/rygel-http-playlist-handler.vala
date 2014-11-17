/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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


/**
 * RygelHTTPPlaylistHandler implements a special handler for generating XML
 * playlists (DIDL_S format as defined by DLNA) on-the-fly.
 */
internal class Rygel.HTTPPlaylistHandler : Rygel.HTTPGetHandler {
    private SerializerType playlist_type;

    public static bool is_supported (string playlist_format) {
        return playlist_format == "DIDL_S" || playlist_format == "M3U";
    }

    public HTTPPlaylistHandler (string playlist_format,
                                Cancellable? cancellable) {
        if (playlist_format == "DIDL_S") {
            this.playlist_type = SerializerType.DIDL_S;
        } else if (playlist_format == "M3U") {
            this.playlist_type = SerializerType.M3UEXT;
        }

        this.cancellable = cancellable;
    }

    public override void add_response_headers (HTTPGet request)
                                               throws HTTPRequestError {
        // TODO: Why do we use response_headers.append instead of set_content_type
        switch (this.playlist_type) {
            case SerializerType.DIDL_S:
                request.msg.response_headers.append ("Content-Type",
                                                     "text/xml");
                break;
            case SerializerType.M3UEXT:
                request.msg.response_headers.append ("ContentType",
                                                     "audio/x-mpegurl");
                break;
            default:
                assert_not_reached ();
        }

        base.add_response_headers (request);
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        try {
            var source = new PlaylistDatasource
                                        (this.playlist_type,
                                         request.object as MediaContainer,
                                         request.http_server,
                                         request.hack);

            return new HTTPResponse (request, this, source);
        } catch (Error error) {
            throw new HTTPRequestError.NOT_FOUND (error.message);
        }
    }

    protected override DIDLLiteResource add_resource
                                        (DIDLLiteObject didl_object,
                                         HTTPGet        request) {
        var protocol = request.http_server.get_protocol ();

        try {
            var res = request.object.add_resource (didl_object, null, protocol);

            // set DLNA profile to get proper contentFeatures header
            if (this.playlist_type == SerializerType.DIDL_S) {
                res.protocol_info.dlna_profile = "DIDL_S";
            }

            return res;
        } catch (Error error) {
            return null as DIDLLiteResource;
        }
    }
}
