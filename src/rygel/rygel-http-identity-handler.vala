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
internal class Rygel.HTTPIdentityHandler : GLib.Object,
                                           Rygel.HTTPRequestHandler {

    public HTTPIdentityHandler () {}

    public virtual void add_response_headers (HTTPRequest request)
                                              throws HTTPRequestError {
        var item = request.item;

        request.msg.response_headers.append ("Content-Type", item.mime_type);
        if (item.size >= 0) {
            request.msg.response_headers.set_content_length (item.size);
        }
        if (item.should_stream ()) {
            if (request.time_range != null) {
                request.time_range.add_response_header (request.msg);
            }
        } else {
            request.msg.response_headers.append ("Accept-Ranges", "bytes");
            if (request.byte_range != null) {
                request.byte_range.add_response_header (request.msg, item.size);
            }
        }

        this.add_content_features_headers (request);
    }

    public virtual HTTPResponse render_body (HTTPRequest request)
                                             throws HTTPRequestError {
        var item = request.item;

        if (item.should_stream ()) {
            Gst.Element src = item.create_stream_source ();
            if (src == null) {
                throw new HTTPRequestError.NOT_FOUND ("Not found");
            }

            return new LiveResponse (request.server,
                                     request.msg,
                                     "RygelLiveResponse",
                                     src,
                                     request.time_range);
        } else {
            if (item.uris.size == 0) {
                throw new HTTPRequestError.NOT_FOUND (
                        "Requested item '%s' didn't provide a URI\n",
                        item.id);
            }

            return new SeekableResponse (request.server,
                                         request.msg,
                                         item.uris.get (0),
                                         request.byte_range,
                                         item.size);
        }
    }

    protected DIDLLiteResource add_resource (DIDLLiteItem didl_item,
                                             HTTPRequest  request)
                                             throws HTTPRequestError {
        return request.item.add_resource (didl_item,
                                          null,
                                          request.http_server.get_protocol ());
    }
}
