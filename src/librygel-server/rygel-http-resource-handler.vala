/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Craig Pratt <craig@ecaspia.com>
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
 * The HTTP handler for HTTP ContentResource requests.
 */
internal class Rygel.HTTPMediaResourceHandler : HTTPGetHandler {
    private MediaObject media_object;
    private string media_resource_name;
    public MediaResource media_resource;

    public HTTPMediaResourceHandler (MediaObject media_object,
                                     string media_resource_name,
                                     Cancellable? cancellable)
                                     throws HTTPRequestError {
        this.media_object = media_object;
        this.cancellable = cancellable;
        this.media_resource_name = media_resource_name;
        var resource = media_object.get_resource_by_name (media_resource_name);

        if (resource == null) {
            throw new HTTPRequestError.NOT_FOUND ("MediaResource %s not found",
                                                  media_resource_name);
        }

        // Handler modifies the resource, so we copy it.
        this.media_resource = resource.dup ();
    }

    public override void add_response_headers (HTTPGet request)
                                               throws HTTPRequestError {
        request.http_server.set_resource_delivery_options (this.media_resource);
        var replacements = request.http_server.get_replacements ();
        var mime_type = MediaObject.apply_replacements
                                     (replacements,
                                      this.media_resource.mime_type);
        request.msg.get_response_headers ().append ("Content-Type", mime_type);

        // Add contentFeatures.dlna.org
        var protocol_info = media_resource.get_protocol_info (replacements);
        if (protocol_info != null) {
            var pi_fields = protocol_info.to_string ().split (":", 4);
            if (pi_fields != null && pi_fields[3] != null) {
                request.msg.get_response_headers ().append ("contentFeatures.dlna.org",
                                                     pi_fields[3]);
            }
        }

        // Chain-up
        base.add_response_headers (request);
    }

    public override string get_default_transfer_mode () {
        // Per DLNA 7.5.4.3.2.33.2, the assumed transfer mode is based on the content type
        // "Streaming" for AV content and "Interactive" for all others
        return media_resource.get_default_transfer_mode ();
    }

    public override bool supports_transfer_mode (string mode) {
        return media_resource.supports_transfer_mode (mode);
    }

    public override HTTPResponse render_body (HTTPGet request)
                                              throws HTTPRequestError {
        try {
            var src = request.object.create_stream_source_for_resource
                                    (request, this.media_resource);
            if (src == null) {
                throw new HTTPRequestError.NOT_FOUND
                              (_("Couldn’t create data source for %s"),
                               this.media_resource.get_name ());
            }

            return new HTTPResponse (request, this, src);
        } catch (Error err) {
            throw new HTTPRequestError.NOT_FOUND (err.message);
        }
    }

    public override int64 get_resource_size () {
        return media_resource.size;
    }

    public override int64 get_resource_duration () {
        return media_resource.duration * TimeSpan.SECOND;
    }

    public override bool supports_byte_seek () {
        return media_resource.supports_arbitrary_byte_seek ()
               || media_resource.supports_limited_byte_seek ();
    }

    public override bool supports_time_seek () {
        return media_resource.supports_arbitrary_time_seek ()
               || media_resource.supports_limited_time_seek ();
    }

    public override bool supports_playspeed () {
        return media_resource.supports_playspeed ();
    }
}
