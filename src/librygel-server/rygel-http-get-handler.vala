/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2010 Andreas Henriksson <andreas@fatal.se>
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;

/**
 * HTTP GET request handler interface.
 */
public abstract class Rygel.HTTPGetHandler: GLib.Object {
    protected const string TRANSFER_MODE_HEADER = "transferMode.dlna.org";

    protected const string TRANSFER_MODE_STREAMING = "Streaming";
    protected const string TRANSFER_MODE_INTERACTIVE = "Interactive";
    protected const string TRANSFER_MODE_BACKGROUND = "Background";

    public Cancellable cancellable { get; set; }

    /**
     * Invokes the handler to add response headers to/for the given HTTP request
     */
    public virtual void add_response_headers (HTTPGet request)
                                              throws HTTPRequestError {
        var mode = request.msg.get_request_headers ().get_one (TRANSFER_MODE_HEADER);

        // Per DLNA 7.5.4.3.2.33.2, if the transferMode header is empty it
        // must be treated as Streaming mode or Interactive, depending upon
        // the content
        if (mode == null) {
            mode = this.get_default_transfer_mode ();
        }
        request.msg.get_response_headers ().append (TRANSFER_MODE_HEADER, mode);

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
     * Returns true if the handler supports the given transfer mode, false
     * otherwise.
     */
    public abstract bool supports_transfer_mode (string mode);

    /**
     * Returns the resource size or -1 if not known.
     */
    public abstract int64 get_resource_size ();

    /**
     * Returns the resource duration (in microseconds) or -1 if not known.
     */
    public virtual int64 get_resource_duration () {
        return -1;
    }

    /**
     * Returns true if the handler supports full random-access byte seek.
     */
    public virtual bool supports_byte_seek () {
        return false;
    }

    /**
     * Returns true if the handler supports full random-access time seek.
     */
    public virtual bool supports_time_seek () {
        return false;
    }

    /**
     * Returns true if the handler supports any play speed requests.
     */
    public virtual bool supports_playspeed () {
        return false;
    }

    /**
     * Create an HTTPResponse object that will render the body.
     */
    public abstract HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError;

}
