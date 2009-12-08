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

using Gst;
using GUPnP;

/**
 * The handler for HTTP transcoding requests.
 */
internal class Rygel.HTTPTranscodeHandler : HTTPRequestHandler {
    private Transcoder transcoder;

    public HTTPTranscodeHandler (Transcoder   transcoder,
                                 Cancellable? cancellable) {
        this.transcoder = transcoder;
        this.cancellable = cancellable;
    }

    public override void add_response_headers (HTTPRequest request)
                                               throws HTTPRequestError {
        request.msg.response_headers.append ("Content-Type",
                                             this.transcoder.mime_type);
        if (request.time_range != null) {
            request.time_range.add_response_headers ();
        }

        // Chain-up
        base.add_response_headers (request);
    }

    public override HTTPResponse render_body (HTTPRequest request)
                                              throws HTTPRequestError {
        var item = request.item;
        var src = item.create_stream_source ();
        if (src == null) {
            throw new HTTPRequestError.NOT_FOUND ("Not found");
        }

        try {
            src = this.transcoder.create_source (item, src);

            return new LiveResponse (request.server,
                                     request.msg,
                                     "RygelLiveResponse",
                                     src,
                                     request.time_range,
                                     this.cancellable);
        } catch (GLib.Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    protected override DIDLLiteResource add_resource (DIDLLiteItem didl_item,
                                                      HTTPRequest  request)
                                                      throws Error {
        return this.transcoder.add_resource (didl_item,
                                             request.item,
                                             request.http_server);
    }
}

