/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2006, 2007, 2008 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jorn Baayen <jorn.baayen@gmail.com>
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

/**
 * Responsible for handling HTTP GET & HEAD client requests.
 */
internal class Rygel.HTTPGet : HTTPRequest {
    private const string TRANSFER_MODE_HEADER = "transferMode.dlna.org";

    public Thumbnail thumbnail;
    public Subtitle subtitle;
    public HTTPSeek seek;

    private int thumbnail_index;
    private int subtitle_index;

    public HTTPGetHandler handler;

    public HTTPGet (HTTPServer   http_server,
                    Soup.Server  server,
                    Soup.Message msg) {
        base (http_server, server, msg);

        this.thumbnail_index = -1;
        this.subtitle_index = -1;
    }

    protected override async void handle () throws Error {
        var header = this.msg.request_headers.get_one (
                                        "getcontentFeatures.dlna.org");

        /* We only entertain 'HEAD' and 'GET' requests */
        if ((this.msg.method != "HEAD" && this.msg.method != "GET") ||
            (header != null && header != "1")) {
            throw new HTTPRequestError.BAD_REQUEST (_("Invalid Request"));
        }

        if (uri.transcode_target != null) {
            var transcoder = this.http_server.get_transcoder (
                                                        uri.transcode_target);
            this.handler = new HTTPTranscodeHandler (transcoder,
                                                     this.cancellable);
        }

        if (this.handler == null) {
            this.handler = new HTTPIdentityHandler (this.cancellable);

            header = this.msg.request_headers.get_one (TRANSFER_MODE_HEADER);

            if (header == "Streaming" &&
                (!this.item.should_stream () ||
                 this.subtitle != null ||
                 this.thumbnail != null)) {
                throw new HTTPRequestError.UNACCEPTABLE (
                                        "Streaming mode not supported for '%s'",
                                        item.id);
            }
        }

        yield this.handle_item_request ();
    }

    protected override async void find_item () throws Error {
        yield base.find_item ();

        if (this.uri.thumbnail_index >= 0) {
            this.thumbnail = this.item.thumbnails.get (
                                        this.uri.thumbnail_index);
        } else if (this.uri.subtitle_index >= 0) {
            this.subtitle = this.item.subtitles.get (this.uri.subtitle_index);
        }
    }

    private async void handle_item_request () throws Error {
        var need_time_seek = HTTPTimeSeek.needed (this);
        var need_byte_seek = HTTPByteSeek.needed (this);

        if ((HTTPTimeSeek.requested (this) && !need_time_seek) ||
            (HTTPByteSeek.requested (this) && !need_byte_seek)) {
            throw new HTTPRequestError.UNACCEPTABLE ("Invalid seek request");
        }

        if (need_time_seek) {
            this.seek = new HTTPTimeSeek (this);
        } else if (need_byte_seek) {
            this.seek = new HTTPByteSeek (this);
        }

        // Add headers
        this.handler.add_response_headers (this);
        debug (_("Following HTTP headers appended to response:"));
        this.msg.response_headers.foreach ((name, value) => {
            debug ("%s : %s", name, value);
        });

        if (this.msg.method == "HEAD") {
            // Only headers requested, no need to send contents
            this.server.unpause_message (this.msg);
            this.end (Soup.KnownStatusCode.OK);

            return;
        }

        var response = this.handler.render_body (this);

        yield response.run ();

        this.end (Soup.KnownStatusCode.NONE);
    }
}

