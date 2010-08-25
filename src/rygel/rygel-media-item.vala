/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
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
using Gst;

private errordomain Rygel.MediaItemError {
    BAD_URI
}

/**
 * Represents a media (Music, Video and Image) item.
 */
public abstract class Rygel.MediaItem : MediaObject {
    public string date;

    // Resource info
    public string mime_type;
    public string dlna_profile;

    public int64 size = -1;     // Size in bytes

    internal bool place_holder = false;

    public MediaItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class) {
        this.id = id;
        this.parent = parent;
        this.title = title;
        this.upnp_class = upnp_class;
    }

    // Live media items need to provide a nice working implementation of this
    // method if they can/do not provide a valid URI
    public virtual Element? create_stream_source () {
        dynamic Element src = null;

        if (this.uris.size != 0) {
            src = Element.make_from_uri (URIType.SRC, this.uris.get (0), null);
        }

        if (src != null) {
            if (src.get_class ().find_property ("blocksize") != null) {
                // The default is usually 4KiB which is not really big enough
                // for most cases so we set this to 65KiB.
                src.blocksize = (long) 65536;
            }

            if (src.get_class ().find_property ("tcp-timeout") != null) {
                // For rtspsrc since some RTSP sources takes a while to start
                // transmitting
                src.tcp_timeout = (int64) 60000000;
            }
        }

        return src;
    }

    // Return true if item should be streamed as a live response with
    // time based seeking, or false to serve directly with byte range
    // seeking.
    public bool should_stream () {
        // Simple heuristic: if size is known and its not image, serve directly.
        return this.streamable () && this.size <= 0;
    }

    public abstract bool streamable ();

    public virtual void add_uri (string uri) {
        this.uris.add (uri);
    }

    internal int compare_transcoders (void *a, void *b) {
        var transcoder1 = (Transcoder) a;
        var transcoder2 = (Transcoder) b;

        return (int) transcoder1.get_distance (this) -
               (int) transcoder2.get_distance (this);
    }

    internal virtual DIDLLiteResource add_resource (
                                        DIDLLiteItem didl_item,
                                        string?      uri,
                                        string       protocol,
                                        string?      import_uri = null)
                                        throws Error {
        var res = didl_item.add_resource ();

        if (uri != null) {
            res.uri = uri;
        }

        if (import_uri != null) {
            res.import_uri = import_uri;
        }

        res.size64 = this.size;

        /* Protocol info */
        res.protocol_info = this.get_protocol_info (uri, protocol);

        return res;
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        var item = media_object as MediaItem;

        switch (property) {
        case "dc:date":
            return this.compare_by_date (item);
        default:
            return base.compare_by_property (item, property);
        }
    }

    internal virtual DIDLLiteItem serialize (DIDLLiteWriter writer)
                                             throws Error {
        var didl_item = writer.add_item ();

        didl_item.id = this.id;
        if (this.parent != null) {
            didl_item.parent_id = this.parent.id;
        } else {
            didl_item.parent_id = "0";
        }

        didl_item.restricted = false;
        didl_item.title = this.title;
        didl_item.upnp_class = this.upnp_class;

        /* We list proxy/transcoding resources first instead of original URIs
         * because some crappy MediaRenderer/ControlPoint implemenation out
         * there just choose the first one in the list instead of the one they
         * can handle.
         */
        if (this.place_holder) {
            this.add_proxy_resources (writer.http_server, didl_item);
        } else {
            // Add the transcoded/proxy URIs first
            this.add_proxy_resources (writer.http_server, didl_item);

            // then original URIs
            bool internal_allowed;
            internal_allowed = writer.http_server.context.interface == "lo" ||
                               writer.http_server.context.host_ip ==
                               "127.0.0.1";
            this.add_resources (didl_item, internal_allowed);
        }

        return didl_item;
    }

    internal virtual void add_proxy_resources (HTTPServer   server,
                                               DIDLLiteItem didl_item)
                                               throws Error {
        // Proxy resource for the original resources
        server.add_proxy_resource (didl_item, this);

        // Transcoding resources
        server.add_resources (didl_item, this);
    }

    protected virtual ProtocolInfo get_protocol_info (string? uri,
                                                      string  protocol) {
        var protocol_info = new ProtocolInfo ();

        protocol_info.mime_type = this.mime_type;
        protocol_info.dlna_profile = this.dlna_profile;
        protocol_info.protocol = protocol;
        protocol_info.dlna_flags = DLNAFlags.DLNA_V15;

        if (this.streamable ()) {
            protocol_info.dlna_flags |= DLNAFlags.STREAMING_TRANSFER_MODE;
        }

        if (!this.should_stream ()) {
            protocol_info.dlna_operation = DLNAOperation.RANGE;
            protocol_info.dlna_flags |= DLNAFlags.BACKGROUND_TRANSFER_MODE |
                                        DLNAFlags.CONNECTION_STALL;
        } else {
            protocol_info.dlna_flags |= DLNAFlags.SENDER_PACED;
        }

        return protocol_info;
    }

    internal string get_protocol_for_uri (string uri) throws Error {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            throw new MediaItemError.BAD_URI (_("Bad URI: %s"), uri);
        }

        if (scheme == "http") {
            return "http-get";
        } else if (scheme == "file") {
            return "internal";
        } else if (scheme == "rtsp") {
            // FIXME: Assuming that RTSP is always accompanied with RTP over UDP
            return "rtsp-rtp-udp";
        } else {
            // Assume the protocol to be the scheme of the URI
            warning (_("Failed to probe protocol for URI %s. Assuming '%s'"),
                     uri,
                     scheme);

            return scheme;
        }
    }

    protected virtual void add_resources (DIDLLiteItem didl_item,
                                          bool         allow_internal)
                                          throws Error {
        foreach (var uri in this.uris) {
            var protocol = this.get_protocol_for_uri (uri);

            if (allow_internal || protocol != "internal") {
                this.add_resource (didl_item, uri, protocol);
            }
        }
    }

    private int compare_by_date (MediaItem item) {
        if (this.date == null) {
            return -1;
        } else if (item.date == null) {
            return 1;
        } else {
            var tv1 = TimeVal ();
            assert (tv1.from_iso8601 (this.date));

            var tv2 = TimeVal ();
            assert (tv2.from_iso8601 (item.date));

            var ret = this.compare_long (tv1.tv_sec, tv2.tv_sec);
            if (ret == 0) {
                ret = this.compare_long (tv1.tv_usec, tv2.tv_usec);
            }

            return ret;
        }
    }

    private int compare_long (long a, long b) {
        if (a < b) {
            return -1;
        } else if (a > b) {
            return 1;
        } else {
            return 0;
        }
    }
}
