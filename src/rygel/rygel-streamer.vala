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

using Gst;
using GUPnP;

public errordomain Rygel.StreamerError {
    UNACCEPTABLE = Soup.KnownStatusCode.NOT_ACCEPTABLE,
    INVALID_RANGE = Soup.KnownStatusCode.BAD_REQUEST,
    OUT_OF_RANGE = Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE
}

public class Rygel.Streamer : GLib.Object {
    private const string SERVER_PATH_PREFIX = "/RygelStreamer";
    private string server_path_root;

    private GUPnP.Context context;
    private List<GstStream> streams;

    public signal void need_stream_source (MediaItem   item,
                                           out Element src);
    public signal void item_requested (string item_id,
                                       out MediaItem item);

    public Streamer (GUPnP.Context context, string name) {
        this.context = context;
        this.streams = new List<GstStream> ();

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

    private void stream_from_gst_source (Element#    src,
                                        Soup.Message msg,
                                        Seek?        seek) throws Error {
        Event seek_event = null;
        if (seek != null) {
            seek_event = new Event.seek (1.0,
                                         seek.format,
                                         SeekFlags.FLUSH,
                                         Gst.SeekType.SET,
                                         seek.start,
                                         Gst.SeekType.SET,
                                         seek.stop);
        }

        GstStream stream = new GstStream (this.context.server,
                                          msg,
                                          "RygelGstStream",
                                          src,
                                          seek_event);
        stream.start ();
        stream.eos += on_eos;

        this.streams.append (stream);
    }

    private void on_eos (GstStream stream) {
        /* Remove the stream from our list. */
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

        Seek seek = null;

        try {
            seek = this.parse_range (msg, item);
        } catch (StreamerError err) {
            warning ("%s", err.message);
            msg.set_status (err.code);
            return;
        }

        // Add headers
        this.add_item_headers (msg, item, seek);

        if (msg.method == "HEAD") {
            // Only headers requested, no need to stream contents
            msg.set_status (Soup.KnownStatusCode.OK);
            return;
        }

        if (item.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            this.handle_interactive_item (msg, item, seek);
        } else {
            this.handle_streaming_item (msg, item, seek);
        }
    }

    private void add_item_headers (Soup.Message msg,
                                   MediaItem    item,
                                   Seek?        seek) {
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

        if (item.res.size > 0) {
            int64 first_byte;
            int64 last_byte;

            if (seek != null) {
                first_byte = seek.start;
                last_byte = seek.stop;
            } else {
                first_byte = 0;
                last_byte = item.res.size - 1;
            }

            // Content-Range: bytes START_BYTE-STOP_BYTE/TOTAL_LENGTH
            var content_range = "bytes " +
                                first_byte.to_string () + "-" +
                                last_byte.to_string () + "/" +
                                item.res.size.to_string ();
            msg.response_headers.append ("Content-Range", content_range);
        }
    }

    private void handle_streaming_item (Soup.Message msg,
                                        MediaItem    item,
                                        Seek?        seek) {
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

        try {
            // Then start the gst stream
            this.stream_from_gst_source (src, msg, seek);
        } catch (Error error) {
            critical ("Error in attempting to start streaming %s: %s",
                      uri,
                      error.message);
        }
    }

    private void handle_interactive_item (Soup.Message msg,
                                          MediaItem    item,
                                          Seek?        seek) {
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

        size_t offset;
        size_t length;
        if (seek != null) {
            offset = (size_t) seek.start;
            length = (size_t) seek.stop + 1;

            assert (offset <= file_length);
            assert (length <= file_length);
        } else {
            offset = 0;
            length = file_length;
        }

        if (seek != null) {
            msg.set_status (Soup.KnownStatusCode.PARTIAL_CONTENT);
        } else {
            msg.set_status (Soup.KnownStatusCode.OK);
        }

        char *data = (char *) contents + offset;

        msg.response_body.append (Soup.MemoryUse.COPY, data, length);
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
    private Seek? parse_range (Soup.Message message,
                                MediaItem    item)
                                throws StreamerError {
            string range;
            string[] range_tokens;
            Seek seek = null;

            range = message.request_headers.get ("Range");
            if (range == null) {
                return seek;
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

            seek = new Seek (Format.BYTES, 0, item.res.size - 1);

            // Get first byte position
            string first_byte = range_tokens[0];
            if (first_byte[0].isdigit ()) {
                seek.start = first_byte.to_int64 ();
            } else if (first_byte  != "") {
                throw new StreamerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            // Get last byte position if specified
            string last_byte = range_tokens[1];
            if (last_byte[0].isdigit ()) {
                seek.stop = last_byte.to_int64 ();
            } else if (last_byte  != "") {
                throw new StreamerError.INVALID_RANGE ("Invalid Range '%s'",
                                                       range);
            }

            if (item.res.size > 0) {
                // shouldn't go beyond actual length of media
                if (seek.start > item.res.size || seek.stop >= item.res.size) {
                    throw new StreamerError.OUT_OF_RANGE (
                            "Range '%s' not setsifiable", range);
                }

                // No need to seek if whole stream is requested
                if (seek.start == 0 && seek.stop == item.res.size - 1) {
                    return null;
                }
            } else if (seek.start == 0) {
                // Might be an attempt to get the size, in which case it's not
                // an error. Just don't seek.
                return null;
            } else {
                throw new StreamerError.UNACCEPTABLE (
                            "Partial download not applicable for item %s",
                            item.id);
            }

            return seek;
        }
}

class Rygel.Seek {
    public Format format;

    public int64 start;
    public int64 stop;

    public Seek (Format format,
                 int64  start,
                 int64  stop) {
        this.format = format;
        this.start = start;
        this.stop = stop;
    }
}

