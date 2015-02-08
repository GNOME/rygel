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
    protected const string TRANSFER_MODE_HEADER = "transferMode.dlna.org";

    protected const string TRANSFER_MODE_STREAMING = "Streaming";
    protected const string TRANSFER_MODE_INTERACTIVE = "Interactive";
    protected const string TRANSFER_MODE_BACKGROUND = "Background";

    public Cancellable cancellable { get; set; }

    // Add response headers.
    /**
     * Invokes the handler to add response headers to/for the given HTTP request
     */
    public virtual void add_response_headers (HTTPGet request)
                                              throws HTTPRequestError {
        var mode = request.msg.request_headers.get_one (TRANSFER_MODE_HEADER);

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
        // Per DLNA 7.5.4.3.2.33.2, if the transferMode header is empty it
        // must be treated as Streaming mode or Interactive, depending upon the content
        if (mode == null) {
            request.msg.response_headers.append (TRANSFER_MODE_HEADER,
                                                 this.get_default_transfer_mode ());
        } else {
            request.msg.response_headers.append (TRANSFER_MODE_HEADER, mode);
        }

        // Handle device-specific hacks that need to change the response
        // headers such as Samsung's subtitle stuff.
        if (request.hack != null) {
            request.hack.modify_headers (request);
        }
    }

    /**
     * Returns the default transfer mode for the handler.
     * The default is "Interactive"
     */
    public virtual string get_default_transfer_mode () {
        return TRANSFER_MODE_INTERACTIVE; // Considering this the default
    }

    /**
     * Returns true if the handler supports the given transfer mode, false otherwise.
     */
    public abstract bool supports_transfer_mode (string mode);

    /**
     * Returns the resource size or -1 if not known.
     */
    public abstract int64 get_resource_size ();

    // Create an HTTPResponse object that will render the body.
    public abstract HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError;

    protected abstract DIDLLiteResource add_resource (DIDLLiteObject didl_object,
                                                      HTTPGet      request)
                                                      throws Error;

}
