/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using GUPnP;
using Gee;

public errordomain Rygel.MediaItemError {
    UNKNOWN_URI_TYPE
}

/**
 * Represents a media (Music, Video and Image) item. Provides basic
 * serialization (to DIDLLiteWriter) implementation.
 */
public class Rygel.MediaItem : MediaObject {
    public static const string IMAGE_CLASS = "object.item.imageItem";
    public static const string VIDEO_CLASS = "object.item.videoItem";
    public static const string AUDIO_CLASS = "object.item.audioItem";
    public static const string MUSIC_CLASS = "object.item.audioItem.musicTrack";

    public string author;
    public string album;
    public string date;
    public string upnp_class;

    public DIDLLiteResource res;

    public int track_number = -1;

    protected Rygel.HTTPServer http_server;

    public MediaItem (string     id,
                      string     parent_id,
                      string     title,
                      string     upnp_class,
                      HTTPServer http_server) {
        this.id = id;
        this.parent_id = parent_id;
        this.title = title;
        this.upnp_class = upnp_class;
        this.http_server = http_server;

        this.res = DIDLLiteResource ();
        this.res.reset ();
    }

    public override void serialize (DIDLLiteWriter didl_writer) throws Error {
        didl_writer.start_item (this.id,
                                this.parent_id,
                                null,
                                false);

        /* Add fields */
        didl_writer.add_string ("title",
                                DIDLLiteWriter.NAMESPACE_DC,
                                null,
                                this.title);

        didl_writer.add_string ("class",
                                DIDLLiteWriter.NAMESPACE_UPNP,
                                null,
                                this.upnp_class);

        if (this.author != null && this.author != "") {
            didl_writer.add_string ("creator",
                                    DIDLLiteWriter.NAMESPACE_DC,
                                    null,
                                    this.author);

            if (this.upnp_class.has_prefix (VIDEO_CLASS)) {
                didl_writer.add_string ("author",
                                        DIDLLiteWriter.NAMESPACE_UPNP,
                                        null,
                                        this.author);
            } else if (this.upnp_class.has_prefix (MUSIC_CLASS)) {
                didl_writer.add_string ("artist",
                                        DIDLLiteWriter.NAMESPACE_UPNP,
                                        null,
                                        this.author);
            }
        }

        if (this.track_number >= 0) {
            didl_writer.add_int ("originalTrackNumber",
                                 DIDLLiteWriter.NAMESPACE_UPNP,
                                 null,
                                 this.track_number);
        }

        if (this.album != null && this.album != "") {
            didl_writer.add_string ("album",
                                    DIDLLiteWriter.NAMESPACE_UPNP,
                                    null,
                                    this.album);
        }

        if (this.date != null && this.date != "") {
            didl_writer.add_string ("date",
                                    DIDLLiteWriter.NAMESPACE_DC,
                                    null,
                                    this.date);
        }

        /* Add resource data */
        /* Protocol info */
        if (this.res.uri != null) {
            string protocol = get_protocol_for_uri (this.res.uri);
            this.res.protocol = protocol;
        }

        this.res.dlna_profile = "MP3"; /* FIXME */

        if (this.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            this.res.dlna_flags |= DLNAFlags.INTERACTIVE_TRANSFER_MODE;
        } else {
            this.res.dlna_flags |= DLNAFlags.STREAMING_TRANSFER_MODE;
        }

        if (this.res.size > 0) {
            this.res.dlna_operation = DLNAOperation.RANGE;
            this.res.dlna_flags |= DLNAFlags.BACKGROUND_TRANSFER_MODE;
        }

        /* Now get the transcoded/proxy URIs */
        var res_list = this.get_transcoded_resources (res);
        foreach (DIDLLiteResource trans_res in res_list) {
            didl_writer.add_res (trans_res);
        }

        /* Add the original res in the end */
        if (this.res.uri != null) {
            didl_writer.add_res (res);
        }

        /* End of item */
        didl_writer.end_item ();
    }

    private string get_protocol_for_uri (string uri) throws Error {
        if (uri.has_prefix ("http")) {
            return "http-get";
        } else if (uri.has_prefix ("file")) {
            return "internal";
        } else if (uri.has_prefix ("rtsp")) {
            // FIXME: Assuming that RTSP is always accompanied with RTP over UDP
            return "rtsp-rtp-udp";
        } else {
            throw new MediaItemError.UNKNOWN_URI_TYPE
                            ("Failed to probe protocol for URI %s", uri);
        }
    }

    // FIXME: We only proxy URIs through our HTTP server for now
    private ArrayList<DIDLLiteResource?>? get_transcoded_resources
                                            (DIDLLiteResource orig_res) {
        if (orig_res.protocol == "http-get")
            return null;

        var resources = new ArrayList<DIDLLiteResource?> ();

        // Copy the original res first
        DIDLLiteResource res = orig_res;

        // Then modify the URI and protocol
        res.uri = this.http_server.create_http_uri_for_item (this);
        res.protocol = "http-get";

        resources.add (res);

        return resources;
    }
}
