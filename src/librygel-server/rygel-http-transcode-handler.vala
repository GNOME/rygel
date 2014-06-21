/*
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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
 * The handler for HTTP transcoding requests.
 */
internal class Rygel.HTTPTranscodeHandler : HTTPGetHandler {
    private Transcoder transcoder;

    public HTTPTranscodeHandler (Transcoder   transcoder,
                                 Cancellable? cancellable) {
        this.transcoder = transcoder;
        this.cancellable = cancellable;
    }

    public override void add_response_headers (HTTPGet request)
                                               throws HTTPRequestError {
        request.msg.response_headers.append ("Content-Type",
                                             this.transcoder.mime_type);
        if (request.seek != null) {
            request.seek.add_response_headers ();
        }

        // Chain-up
        base.add_response_headers (request);
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        var item = request.object as MediaFileItem;
        var src = item.create_stream_source
                                        (request.http_server.context.host_ip);
        if (src == null) {
            throw new HTTPRequestError.NOT_FOUND (_("Not found"));
        }

        try {
            src = this.transcoder.create_source (item, src);

            return new HTTPResponse (request, this, src);
        } catch (GLib.Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    protected override DIDLLiteResource add_resource
                                        (DIDLLiteObject didl_object,
                                         HTTPGet      request)
                                        throws Error {
        return this.transcoder.add_resource (didl_object as DIDLLiteItem,
                                             request.object as MediaFileItem,
                                             request.http_server);
    }
}
