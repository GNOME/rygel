/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2010 Andreas Henriksson <andreas@fatal.se>
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

/**
 * HTTP GET request handler interface.
 */
internal abstract class Rygel.HTTPGetHandler: GLib.Object {
    private const string TRANSFER_MODE_HEADER = "transferMode.dlna.org";

    public Cancellable cancellable { get; set; }

    // Add response headers.
    public virtual void add_response_headers (HTTPGet request)
                                              throws HTTPRequestError {
        var mode = request.msg.request_headers.get_one (TRANSFER_MODE_HEADER);
        if (mode != null) {
            // FIXME: Is it OK to just copy the value of this header from
            // request to response? All we do to entertain this header is to
            // set the priority of IO operations.
            request.msg.response_headers.append (TRANSFER_MODE_HEADER, mode);
        }

        // Yes, I know this is not the ideal code to just get a specific
        // string for an HTTP header but if you think you can come-up with
        // something better, be my guest and provide a patch.
        var didl_writer = new GUPnP.DIDLLiteWriter (null);
        var didl_item = didl_writer.add_item ();
        try {
            var resource = this.add_resource (didl_item, request);
            if (resource != null) {
                var tokens = resource.protocol_info.to_string ().split (":", 4);
                assert (tokens.length == 4);

                request.msg.response_headers.append ("contentFeatures.dlna.org",
                                                     tokens[3]);
            }
        } catch (Error err) {
            warning ("Received request for 'contentFeatures.dlna.org' but " +
                       "failed to provide the value in response headers");
        }

        // Handle device-specific hacks that need to change the response
        // headers such as Samsung's subtitle stuff.
        if (request.hack != null) {
            request.hack.modify_headers (request);
        }

        request.msg.response_headers.append ("Connection", "close");
    }

    public virtual bool knows_size (HTTPGet request) {
        return false;
    }

    // Create an HTTPResponse object that will render the body.
    public abstract HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError;

    protected abstract DIDLLiteResource add_resource (DIDLLiteObject didl_object,
                                                      HTTPGet      request)
                                                      throws Error;

}
