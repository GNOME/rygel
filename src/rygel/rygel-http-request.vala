/*
 * Copyright (C) 2008, 2009 Nokia Corporation, all rights reserved.
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

using Rygel;
using Gst;

internal errordomain Rygel.HTTPRequestError {
    UNACCEPTABLE = Soup.KnownStatusCode.NOT_ACCEPTABLE,
    INVALID_RANGE = Soup.KnownStatusCode.BAD_REQUEST,
    OUT_OF_RANGE = Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE,
    BAD_REQUEST = Soup.KnownStatusCode.BAD_REQUEST,
    NOT_FOUND = Soup.KnownStatusCode.NOT_FOUND
}

/**
 * Responsible for handling HTTP client requests.
 */
internal class Rygel.HTTPRequest : GLib.Object, Rygel.StateMachine {
    private unowned HTTPServer http_server;
    private MediaContainer root_container;
    private Soup.Server server;
    private Soup.Message msg;
    private HashTable<string,string>? query;

    private HTTPResponse response;

    private string item_id;
    private Transcoder transcoder;
    private MediaItem item;
    private Seek seek;

    private Cancellable cancellable;

    public HTTPRequest (HTTPServer                http_server,
                        Soup.Server               server,
                        Soup.Message              msg,
                        HashTable<string,string>? query) {
        this.http_server = http_server;
        this.root_container = http_server.root_container;
        this.server = server;
        this.msg = msg;
        this.query = query;

        this.server.pause_message (this.msg);
    }

    public void run (Cancellable? cancellable) {
        this.cancellable = cancellable;

        if (this.msg.method != "HEAD" && this.msg.method != "GET") {
            /* We only entertain 'HEAD' and 'GET' requests */
            this.handle_error (
                        new HTTPRequestError.BAD_REQUEST ("Invalid Request"));
            return;
        }

        if (this.query != null) {
            this.item_id = this.query.lookup ("itemid");
            var transcode_target = this.query.lookup ("transcode");
            if (transcode_target != null) {
                this.transcoder = this.http_server.get_transcoder (
                                                    transcode_target);
            }
        }

        if (this.item_id == null) {
            this.handle_error (new HTTPRequestError.NOT_FOUND ("Not Found"));
            return;
        }

        // Fetch the requested item
        this.root_container.find_object (this.item_id,
                                         null,
                                         this.on_item_found);
    }

    private void stream_from_gst_source (owned Element src) throws Error {
        var response = new LiveResponse (this.server,
                                         this.msg,
                                         "RygelLiveResponse",
                                         src);
        this.response = response;
        response.completed += on_response_completed;

        response.run (this.cancellable);
    }

    private void serve_uri (string uri, size_t size) {
        var response = new SeekableResponse (this.server,
                                             this.msg,
                                             uri,
                                             this.seek,
                                             size);
        this.response = response;
        response.completed += on_response_completed;

        response.run (this.cancellable);
    }

    private void on_response_completed (HTTPResponse response) {
        this.end (Soup.KnownStatusCode.NONE);
    }

    private void handle_item_request () {
        try {
            this.parse_range ();
        } catch (Error error) {
            this.handle_error (error);
            return;
        }

        // Add headers
        this.add_item_headers ();

        if (this.msg.method == "HEAD") {
            // Only headers requested, no need to send contents
            this.end (Soup.KnownStatusCode.OK);
            return;
        }

        // Just use the first URI available
        string uri = null;
        if (this.item.uris.size != 0) {
            uri = this.item.uris.get (0);
        }

        if (this.item.size > 0 && this.transcoder == null) {
            this.handle_interactive_item (uri);
        } else {
            this.handle_streaming_item (uri);
        }
    }

    private void add_item_headers () {
        if (this.transcoder != null) {
            this.msg.response_headers.append ("Content-Type",
                                              this.transcoder.mime_type);
            return;
        }

        if (this.item.mime_type != null) {
            this.msg.response_headers.append ("Content-Type",
                                              this.item.mime_type);
        }

        if (this.item.size >= 0) {
            this.msg.response_headers.set_content_length (this.item.size);
        }

        if (this.item.size > 0) {
            int64 first_byte;
            int64 last_byte;

            if (this.seek != null) {
                first_byte = this.seek.start;
                last_byte = this.seek.stop;
            } else {
                first_byte = 0;
                last_byte = this.item.size - 1;
            }

            // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
            var content_range = "bytes " +
                                first_byte.to_string () + "-" +
                                last_byte.to_string () + "/" +
                                this.item.size.to_string ();
            this.msg.response_headers.append ("Content-Range", content_range);
            this.msg.response_headers.append ("Accept-Ranges", "bytes");
        }
    }

    private void handle_streaming_item (string? uri) {
        dynamic Element src = null;

        if (uri != null) {
            // URI provided, try to create source element from it
            src = Element.make_from_uri (URIType.SRC, uri, null);
        } else {
            // No URI provided, ask for source element
            src = this.item.create_stream_source ();
        }

        if (src == null) {
            this.handle_error (new HTTPRequestError.NOT_FOUND ("Not Found"));
            return;
        }

        // For rtspsrc since some RTSP sources takes a while to start
        // transmitting
        src.tcp_timeout = (int64) 60000000;

        try {
            if (this.transcoder != null) {
                src = this.transcoder.create_source (src);
            }

            // Then start the gst stream
            this.stream_from_gst_source (src);
        } catch (Error error) {
            this.handle_error (error);
            return;
        }
    }

    private void handle_interactive_item (string? uri) {
        if (uri == null) {
            var error = new HTTPRequestError.NOT_FOUND (
                                "Requested item '%s' didn't provide a URI\n",
                                this.item.id);
            this.handle_error (error);
            return;
        }

        this.serve_uri (uri, this.item.size);
    }

    private void parse_range () throws HTTPRequestError {
            string range;
            string[] range_tokens;

            range = this.msg.request_headers.get ("Range");
            if (range == null) {
                return;
            }

            // We have a Range header. Parse.
            if (!range.has_prefix ("bytes=")) {
                throw new HTTPRequestError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            range_tokens = range.offset (6).split ("-", 2);

            if (range_tokens[0] == null || range_tokens[1] == null) {
                throw new HTTPRequestError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            this.seek = new Seek (Format.BYTES, 0, this.item.size - 1);

            // Get first byte position
            string first_byte = range_tokens[0];
            if (first_byte[0].isdigit ()) {
                this.seek.start = first_byte.to_int64 ();
            } else if (first_byte  != "") {
                throw new HTTPRequestError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            // Get last byte position if specified
            string last_byte = range_tokens[1];
            if (last_byte[0].isdigit ()) {
                this.seek.stop = last_byte.to_int64 ();
            } else if (last_byte  != "") {
                throw new HTTPRequestError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            if (this.item.size > 0) {
                // shouldn't go beyond actual length of media
                if (this.seek.start > this.item.size ||
                    this.seek.length > this.item.size) {
                    throw new HTTPRequestError.OUT_OF_RANGE (
                            "Range '%s' not setsifiable", range);
                }

                // No need to seek if whole stream is requested
                if (this.seek.start == 0 &&
                    this.seek.length == this.item.size) {
                    this.seek == null;
                    return;
                }
            } else if (this.seek.start == 0) {
                // Might be an attempt to get the size, in which case it's not
                // an error. Just don't seek.
                this.seek == null;
                return;
            } else {
                throw new HTTPRequestError.UNACCEPTABLE (
                            "Partial download not applicable for item %s",
                            this.item.id);
            }
    }

    private void on_item_found (GLib.Object source_object,
                                AsyncResult res) {
        var container = (MediaContainer) source_object;

        MediaObject media_object;
        try {
            media_object = container.find_object_finish (res);
        } catch (Error err) {
            this.handle_error (err);
            return;
        }

        if (media_object == null || !(media_object is MediaItem)) {
            this.handle_error (new HTTPRequestError.NOT_FOUND (
                                        "requested item '%s' not found",
                                        this.item_id));
            return;
        }

        this.item = (MediaItem) media_object;

        this.handle_item_request ();
    }

    private void handle_error (Error error) {
        warning ("%s", error.message);

        uint status;
        if (error is HTTPRequestError) {
            status = error.code;
        } else {
            status = Soup.KnownStatusCode.NOT_FOUND;
        }

        this.end (status);
    }

    public void end (uint status) {
        if (status != Soup.KnownStatusCode.NONE) {
            this.msg.set_status (status);
        }

        this.completed ();
    }
}

