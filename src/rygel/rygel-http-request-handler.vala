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

using Rygel;
using GUPnP;

/**
 * HTTP request handler interface.
 */
internal interface Rygel.HTTPRequestHandler: GLib.Object {
    // Add response headers.
    public abstract void add_response_headers (HTTPRequest request)
                                               throws HTTPRequestError;

    // Create an HTTPResponse object that will render the body.
    public abstract HTTPResponse render_body (HTTPRequest request)
                                              throws HTTPRequestError;

    public void add_content_features_headers (HTTPRequest request)
                                              throws HTTPRequestError {
        var didl_writer = new GUPnP.DIDLLiteWriter (null);
        var didl_item = didl_writer.add_item ();
        var resource = this.add_resource (didl_item, request);
        var tokens = resource.protocol_info.to_string ().split (":", 4);
        assert (tokens.length == 4);

        request.msg.response_headers.append ("contentFeatures.dlna.org",
                                             tokens[3]);
    }

    protected abstract DIDLLiteResource add_resource (DIDLLiteItem didl_item,
                                                      HTTPRequest  request)
                                                      throws HTTPRequestError;
}
