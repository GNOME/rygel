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

using Gst;
using GUPnP;
using Gee;

public errordomain Rygel.HTTPServerError {
    UNACCEPTABLE = Soup.KnownStatusCode.NOT_ACCEPTABLE,
    INVALID_RANGE = Soup.KnownStatusCode.BAD_REQUEST,
    OUT_OF_RANGE = Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE
}

public class Rygel.HTTPServer : GLib.Object {
    private const string SERVER_PATH_PREFIX = "/RygelHTTPServer";
    private string path_root;

    private GUPnP.Context context;
    private ArrayList<HTTPResponse> responses;

    public signal void need_stream_source (MediaItem   item,
                                           out Element src);
    public signal void item_requested (string item_id,
                                       out MediaItem item);

    public HTTPServer (GUPnP.Context context, string name) {
        this.context = context;
        this.responses = new ArrayList<HTTPResponse> ();

        this.path_root = SERVER_PATH_PREFIX + "/" + name;

        context.server.add_handler (this.path_root, server_handler);
    }

    public void destroy () {
        context.server.remove_handler (this.path_root);
    }

    private string create_uri_for_path (string path) {
        return "http://%s:%u%s%s".printf (this.context.host_ip,
                                          this.context.port,
                                          this.path_root,
                                          path);
    }

    public string create_http_uri_for_item (MediaItem item) {
        string escaped = Uri.escape_string (item.id, "", true);
        string query = "?itemid=%s".printf (escaped);

        return create_uri_for_path (query);
    }

    private void stream_from_gst_source (Element#     src,
                                         Soup.Message msg) throws Error {
        var response = new LiveResponse (this.context.server,
                                         msg,
                                         "RygelLiveResponse",
                                         src);
        response.start ();
        response.ended += on_response_ended;

        this.responses.add (response);
    }

    private void serve_uri (string       uri,
                            Soup.Message msg,
                            Seek?        seek,
                            size_t       size) throws Error {
        var response = new SeekableResponse (this.context.server,
                                             msg,
                                             uri,
                                             seek,
                                             size);
        response.ended += on_response_ended;

        this.responses.add (response);
    }

    private void on_response_ended (HTTPResponse response) {
        /* Remove the response from our list. */
        this.responses.remove (response);
    }

    private void server_handler (Soup.Server               server,
                                 Soup.Message              msg,
                                 string                    server_path,
                                 HashTable<string,string>? query,
                                 Soup.ClientContext        soup_client) {
        if (msg.method != "HEAD" && msg.method != "GET") {
            /* We only entertain 'HEAD' and 'GET' requests */
            msg.set_status (Soup.KnownStatusCode.BAD_REQUEST);
            return;
        }

        string item_id = null;
        if (query != null) {
            item_id = query.lookup ("itemid");
        }

        if (item_id == null) {
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        this.handle_item_request (msg, item_id);
    }

    private void handle_item_request (Soup.Message msg,
                                      string       item_id) {
        MediaItem item;

        // Signal the requestion for an item
        this.item_requested (item_id, out item);
        if (item == null) {
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        Seek seek = null;

        try {
            seek = this.parse_range (msg, item);
        } catch (HTTPServerError err) {
            warning ("%s", err.message);
            msg.set_status (err.code);
            return;
        }

        // Add headers
        this.add_item_headers (msg, item, seek);

        if (msg.method == "HEAD") {
            // Only headers requested, no need to send contents
            msg.set_status (Soup.KnownStatusCode.OK);
            return;
        }

        if (item.size > 0) {
            this.handle_interactive_item (msg, item, seek);
        } else {
            this.handle_streaming_item (msg, item);
        }
    }

    private void add_item_headers (Soup.Message msg,
                                   MediaItem    item,
                                   Seek?        seek) {
        if (item.mime_type != null) {
            msg.response_headers.append ("Content-Type", item.mime_type);
        }

        if (item.size >= 0) {
            msg.response_headers.append ("Content-Length",
                                         item.size.to_string ());
        }

        if (item.size > 0) {
            int64 first_byte;
            int64 last_byte;

            if (seek != null) {
                first_byte = seek.start;
                last_byte = seek.stop;
            } else {
                first_byte = 0;
                last_byte = item.size - 1;
            }

            // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
            var content_range = "bytes " +
                                first_byte.to_string () + "-" +
                                last_byte.to_string () + "/" +
                                item.size.to_string ();
            msg.response_headers.append ("Content-Range", content_range);
            msg.response_headers.append ("Accept-Ranges", "bytes");
        }
    }

    private void handle_streaming_item (Soup.Message msg,
                                        MediaItem    item) {
        string uri = item.uri;
        dynamic Element src = null;

        if (uri != null) {
            // URI provided, try to create source element from it
            src = Element.make_from_uri (URIType.SRC, uri, null);
        } else {
            // No URI provided, ask for source element directly
            this.need_stream_source (item, out src);
        }

        if (src == null) {
            warning ("Failed to create source element for item: %s\n",
                     item.id);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        // For rtspsrc since some RTSP sources takes a while to start
        // transmitting
        src.tcp_timeout = (int64) 60000000;

        try {
            // Then start the gst stream
            this.stream_from_gst_source (src, msg);
        } catch (Error error) {
            critical ("Error in attempting to start streaming %s: %s",
                      uri,
                      error.message);
        }
    }

    private void handle_interactive_item (Soup.Message msg,
                                          MediaItem    item,
                                          Seek?        seek) {
        string uri = item.uri;

        if (uri == null) {
            warning ("Requested item '%s' didn't provide a URI\n", item.id);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        try {
            this.serve_uri (uri, msg, seek, item.size);
        } catch (Error error) {
            warning ("Error in attempting to serve %s: %s",
                     uri,
                     error.message);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
        }
    }

    /* Parses the HTTP Range header on @message and sets:
     *
     * @offset to the requested offset (left unchanged if none specified),
     * @length to the requested length (left unchanged if none specified).
     *
     * Both @offset and @length are expected to be initialised to their default
     * values. Throws a #HTTPServerError in case of error.
     *
     * Returns %true a range header was found, false otherwise. */
    private Seek? parse_range (Soup.Message message,
                                MediaItem   item)
                                throws      HTTPServerError {
            string range;
            string[] range_tokens;
            Seek seek = null;

            range = message.request_headers.get ("Range");
            if (range == null) {
                return seek;
            }

            // We have a Range header. Parse.
            if (!range.has_prefix ("bytes=")) {
                throw new HTTPServerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            range_tokens = range.offset (6).split ("-", 2);

            if (range_tokens[0] == null || range_tokens[1] == null) {
                throw new HTTPServerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            seek = new Seek (Format.BYTES, 0, item.size - 1);

            // Get first byte position
            string first_byte = range_tokens[0];
            if (first_byte[0].isdigit ()) {
                seek.start = first_byte.to_int64 ();
            } else if (first_byte  != "") {
                throw new HTTPServerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            // Get last byte position if specified
            string last_byte = range_tokens[1];
            if (last_byte[0].isdigit ()) {
                seek.stop = last_byte.to_int64 ();
            } else if (last_byte  != "") {
                throw new HTTPServerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            if (item.size > 0) {
                // shouldn't go beyond actual length of media
                if (seek.start > item.size ||
                    seek.length > item.size) {
                    throw new HTTPServerError.OUT_OF_RANGE (
                            "Range '%s' not setsifiable", range);
                }

                // No need to seek if whole stream is requested
                if (seek.start == 0 && seek.length == item.size) {
                    return null;
                }
            } else if (seek.start == 0) {
                // Might be an attempt to get the size, in which case it's not
                // an error. Just don't seek.
                return null;
            } else {
                throw new HTTPServerError.UNACCEPTABLE (
                            "Partial download not applicable for item %s",
                            item.id);
            }

            return seek;
        }
}

