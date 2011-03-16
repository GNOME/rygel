/*
 * Copyright (C) 2008, 2009 Nokia Corporation.
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

// An HTTP request handler that passes the item content through as is.
internal class Rygel.HTTPIdentityHandler : Rygel.HTTPGetHandler {

    public HTTPIdentityHandler (Cancellable? cancellable) {
        this.cancellable = cancellable;
    }

    public override void add_response_headers (HTTPGet request)
                                               throws HTTPRequestError {
        if (request.subtitle != null) {
           request.msg.response_headers.append ("Content-Type",
                                                request.subtitle.mime_type);
        } else if (request.thumbnail != null) {
            request.msg.response_headers.append ("Content-Type",
                                                 request.thumbnail.mime_type);
        } else {
            request.msg.response_headers.append ("Content-Type",
                                                 request.item.mime_type);
        }

        if (request.seek != null) {
            request.seek.add_response_headers ();
        }

        // Chain-up
        base.add_response_headers (request);
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        try {
            return this.render_body_real (request);
        } catch (Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    protected override DIDLLiteResource add_resource (DIDLLiteItem didl_item,
                                                      HTTPGet      request)
                                                      throws Error {
        var protocol = request.http_server.get_protocol ();

        if (request.thumbnail != null) {
            return request.thumbnail.add_resource (didl_item, protocol);
        } else {
            return request.item.add_resource (didl_item, null, protocol);
        }
    }

    private HTTPResponse render_body_real (HTTPGet request) throws Error {
        if (request.subtitle != null ||
            request.thumbnail != null ||
            !(request.item.should_stream ())) {
            return new HTTPSeekableResponse (request, this);
        } else {
            return new HTTPGstResponse (request, this);
        }
    }
}
