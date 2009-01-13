/*
 * Copyright (C) 2008, 2009 Nokia Corporation, all rights reserved.
 * Copyright (C) 2006, 2007, 2008 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jorn Baayen <jorn.baayen@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Gee;
using Gst;
using GUPnP;

public errordomain Rygel.StreamerError {
    INVALID_RANGE = Soup.KnownStatusCode.BAD_REQUEST,
    OUT_OF_RANGE = Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE
}

public class Rygel.Streamer : GLib.Object {
    private const string SERVER_PATH_PREFIX = "/RygelStreamer";
    private string server_path_root;

    private GUPnP.Context context;
    private HashMap<Stream,GstStream> streams;

    public signal void need_stream_source (MediaItem   item,
                                           out Element src);
    public signal void item_requested (string item_id,
                                       out MediaItem item);

    public Streamer (GUPnP.Context context, string name) {
        this.context = context;
        this.streams = new HashMap<Stream,GstStream> ();

        this.server_path_root = SERVER_PATH_PREFIX + "/" + name;

        context.server.add_handler (this.server_path_root, server_handler);
    }

    private string create_uri_for_path (string path) {
        return "http://%s:%u%s%s".printf (this.context.host_ip,
                                          this.context.port,
                                          this.server_path_root,
                                          path);
    }

    public string create_http_uri_for_item (MediaItem item) {
        string escaped = Uri.escape_string (item.id, "", true);
        string query = "?itemid=%s".printf (escaped);

        return create_uri_for_path (query);
    }

    public void stream_from_gst_source (Element# src,
                                        Stream   stream,
                                        Event?   seek_event) throws Error {
        GstStream gst_stream = new GstStream (stream,
                                              "RygelGstStream",
                                              src,
                                              seek_event);

        gst_stream.set_state (State.PLAYING);
        stream.eos += on_eos;

        this.streams.set (stream, gst_stream);
    }

    private void on_eos (Stream stream) {
        GstStream gst_stream = this.streams.get (stream);
        if (gst_stream == null)
            return;

        /* We don't need to wait for state change since downstream state changes
         * are guaranteed to be synchronous.
         */
        gst_stream.set_state (State.NULL);

        /* Remove the associated Gst stream. */
        this.streams.remove (stream);
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
            warning ("Requested item '%s' not found\n", item_id);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        size_t offset = 0;
        size_t length = item.res.size;
        bool got_range;

        try {
            got_range = this.parse_range (msg, out offset, out length);
        } catch (StreamerError err) {
            warning ("%s", err.message);
            msg.set_status (err.code);
            return;
        }

        if (item.res.size == -1 && got_range) {
            warning ("Partial download not applicable for item %s", item_id);
            msg.set_status (Soup.KnownStatusCode.NOT_ACCEPTABLE);
            return;
        }

        bool partial = got_range && (offset != 0 || length < item.res.size);

        // Add headers
        this.add_item_headers (msg, item, partial, offset, length);

        if (msg.method == "HEAD") {
            // Only headers requested, no need to stream contents
            msg.set_status (Soup.KnownStatusCode.OK);
            return;
        }

        if (item.upnp_class == MediaItem.IMAGE_CLASS) {
            this.handle_interactive_item (msg, item, partial, offset, length);
        } else {
            this.handle_streaming_item (msg, item, partial, offset, length);
        }
    }

    private void add_item_headers (Soup.Message msg,
                                   MediaItem    item,
                                   bool         partial_content,
                                   size_t       offset,
                                   size_t       length) {
        if (item.res.mime_type != null) {
            msg.response_headers.append ("Content-Type", item.res.mime_type);
        }

        if (item.res.size >= 0) {
            msg.response_headers.append ("Content-Length",
                                         item.res.size.to_string ());
        }

        if (DLNAOperation.RANGE in item.res.dlna_operation) {
            msg.response_headers.append ("Accept-Ranges", "bytes");
        }

        if (partial_content) {
            // Content-Range: bytes OFFSET-LENGTH/TOTAL_LENGTH
            var content_range = "bytes " +
                                offset.to_string () + "-" +
                                (length - 1).to_string () + "/" +
                                item.res.size.to_string ();

            msg.response_headers.append ("Content-Range", content_range);
        }
    }

    private void handle_streaming_item (Soup.Message msg,
                                        MediaItem    item,
                                        bool         partial_content,
                                        size_t       offset,
                                        size_t       length) {
        string uri = item.res.uri;
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

        // create a stream for it
        var stream = new Stream (this.context.server, msg);
        try {
            // Create the seek event if needed
            Event seek_event = null;

            if (partial_content) {
                seek_event = new Event.seek (1.0,
                                             Format.BYTES,
                                             SeekFlags.FLUSH,
                                             Gst.SeekType.SET,
                                             offset,
                                             Gst.SeekType.SET,
                                             length);
            }

            // Then attach the gst source to stream we are good to go
            this.stream_from_gst_source (src, stream, seek_event);
        } catch (Error error) {
            critical ("Error in attempting to start streaming %s: %s",
                      uri,
                      error.message);
        }
    }

    private void handle_interactive_item (Soup.Message msg,
                                          MediaItem    item,
                                          bool         partial_content,
                                          size_t       offset,
                                          size_t       length) {
        string uri = item.res.uri;

        if (uri == null) {
            warning ("Requested item '%s' didn't provide a URI\n", item.id);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        File file = File.new_for_uri (uri);

        string contents;
        size_t file_length;
        try {
           file.load_contents (null,
                               out contents,
                               out file_length,
                               null);
        } catch (Error error) {
            warning ("Failed to load contents from URI: %s: %s\n",
                     uri,
                     error.message);
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        assert (offset <= file_length);
        assert (length <= file_length);

        if (partial_content) {
            msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            msg.set_status (Soup.KnownStatusCode.OK);
        }

        msg.response_body.append (Soup.MemoryUse.COPY,
                                  contents.offset ((long) offset),
                                  length);
    }

    /* Parses the HTTP Range header on @message and sets:
     *
     * @offset to the requested offset (left unchanged if none specified),
     * @length to the requested length (left unchanged if none specified).
     *
     * Both @offset and @length are expected to be initialised to their default
     * values. Throws a #StreamerError in case of error.
     *
     * Returns %true a range header was found, false otherwise. */
    private bool parse_range (Soup.Message message,
                              out size_t   offset,
                              out size_t   length)
                              throws StreamerError {
            string range;
            string[] range_tokens;

            range = message.request_headers.get ("Range");
            if (range == null) {
                return false;
            }

            // We have a Range header. Parse.
            if (!range.has_prefix ("bytes=")) {
                throw new StreamerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            range_tokens = range.offset (6).split ("-", 2);

            if (range_tokens[0] == null || range_tokens[1] == null) {
                throw new StreamerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            // Get first byte position
            string first_byte = range_tokens[0];
            if (first_byte[0].isdigit ()) {
                offset = first_byte.to_long ();
            } else if (first_byte  != "") {
                throw new StreamerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            // Save the actual length
            size_t actual_length = length;

            // Get last byte position if specified
            string last_byte = range_tokens[1];
            if (last_byte[0].isdigit ()) {
                length = last_byte.to_long ();
            } else if (last_byte  != "") {
                throw new StreamerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            // Offset shouldn't go beyond actual length of media
            if (offset > actual_length || length > actual_length) {
                throw new StreamerError.OUT_OF_RANGE (
                                    "Range '%s' not setsifiable", range);
            }

            return true;
        }
}

