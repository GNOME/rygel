/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
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
using Gee;

internal errordomain Rygel.DIDLLiteWriterError {
    UNKNOWN_URI_TYPE,
    UNSUPPORTED_OBJECT
}

/**
 * Responsible for serializing media objects.
 */
internal class Rygel.DIDLLiteWriter : GUPnP.DIDLLiteWriter {
    private Rygel.HTTPServer http_server;

    public DIDLLiteWriter (HTTPServer http_server) {
        this.http_server = http_server;
    }

    public void serialize (MediaObject media_object) throws Error {
        if (media_object is MediaItem) {
            this.serialize_item ((MediaItem) media_object);
        } else if (media_object is MediaContainer) {
            this.serialize_container ((MediaContainer) media_object);
        } else {
            throw new DIDLLiteWriterError.UNSUPPORTED_OBJECT (
                "Unable to serialize unsupported object");
        }
    }

    private void serialize_item (MediaItem item) throws Error {
        this.start_item (item.id,
                         item.parent.id,
                         null,
                         false);

        /* Add fields */
        this.add_string ("title",
                         GUPnP.DIDLLiteWriter.NAMESPACE_DC,
                         null,
                         item.title);

        this.add_string ("class",
                         GUPnP.DIDLLiteWriter.NAMESPACE_UPNP,
                         null,
                         item.upnp_class);

        if (item.author != null && item.author != "") {
            this.add_string ("creator",
                             GUPnP.DIDLLiteWriter.NAMESPACE_DC,
                             null,
                             item.author);

            if (item.upnp_class.has_prefix (MediaItem.VIDEO_CLASS)) {
                this.add_string ("author",
                                 GUPnP.DIDLLiteWriter.NAMESPACE_UPNP,
                                 null,
                                 item.author);
            } else if (item.upnp_class.has_prefix (MediaItem.MUSIC_CLASS)) {
                this.add_string ("artist",
                                 GUPnP.DIDLLiteWriter.NAMESPACE_UPNP,
                                 null,
                                 item.author);
            }
        }

        if (item.track_number >= 0) {
            this.add_int ("originalTrackNumber",
                          GUPnP.DIDLLiteWriter.NAMESPACE_UPNP,
                          null,
                          item.track_number);
        }

        if (item.album != null && item.album != "") {
            this.add_string ("album",
                             GUPnP.DIDLLiteWriter.NAMESPACE_UPNP,
                             null,
                             item.album);
        }

        if (item.date != null && item.date != "") {
            this.add_string ("date",
                             GUPnP.DIDLLiteWriter.NAMESPACE_DC,
                             null,
                             item.date);
        }

        /* Add resource data */
        var res_list = this.get_original_res_list (item);

        /* Now get the transcoded/proxy URIs */
        var trans_res_list = this.get_transcoded_resources (item, res_list);
        foreach (DIDLLiteResource trans_res in trans_res_list) {
            this.add_res (trans_res);
        }

        /* Add the original resources in the end */
        foreach (DIDLLiteResource res in res_list) {
            this.add_res (res);
        }

        /* End of item */
        this.end_item ();
    }

    private void serialize_container (MediaContainer container) throws Error {
        string parent_id;

        if (container.parent != null) {
            parent_id = container.parent.id;
        } else {
            parent_id = "-1";
        }

        this.start_container (container.id,
                              parent_id,
                              (int) container.child_count,
                              false,
                              false);

        this.add_string ("class",
                         GUPnP.DIDLLiteWriter.NAMESPACE_UPNP,
                         null,
                         "object.container.storageFolder");

        this.add_string ("title",
                         GUPnP.DIDLLiteWriter.NAMESPACE_DC,
                         null,
                         container.title);

        /* End of Container */
        this.end_container ();
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
            throw new DIDLLiteWriterError.UNKNOWN_URI_TYPE
                            ("Failed to probe protocol for URI %s", uri);
        }
    }

    // FIXME: We only proxy URIs through our HTTP server for now
    private ArrayList<DIDLLiteResource?>? get_transcoded_resources
                                (MediaItem                    item,
                                 ArrayList<DIDLLiteResource?> orig_res_list)
                                 throws Error {
        var resources = new ArrayList<DIDLLiteResource?> ();

        if (http_res_present (orig_res_list)) {
            return resources;
        }

        // Create the HTTP URI
        var uri = this.http_server.create_http_uri_for_item (item);
        DIDLLiteResource res = create_res (item, uri);
        res.protocol = "http-get";

        resources.add (res);

        return resources;
    }

    private bool http_res_present (ArrayList<DIDLLiteResource?> res_list) {
        bool present = false;

        foreach (var res in res_list) {
            if (res.protocol == "http-get") {
                present = true;

                break;
            }
        }

        return present;
    }

    private ArrayList<DIDLLiteResource?> get_original_res_list (MediaItem item)
                                                               throws Error {
        var resources = new ArrayList<DIDLLiteResource?> ();

        foreach (var uri in item.uris) {
            DIDLLiteResource res = create_res (item, uri);

            resources.add (res);
        }

        return resources;
    }

    private DIDLLiteResource create_res (MediaItem item,
                                         string    uri)
                                         throws Error {
        DIDLLiteResource res = DIDLLiteResource ();
        res.reset ();

        res.uri = uri;
        res.mime_type = item.mime_type;

        res.size = item.size;
        res.duration = item.duration;
        res.bitrate = item.bitrate;

        res.sample_freq = item.sample_freq;
        res.bits_per_sample = item.bits_per_sample;
        res.n_audio_channels = item.n_audio_channels;

        res.width = item.width;
        res.height = item.height;
        res.color_depth = item.color_depth;

        /* Protocol info */
        if (res.uri != null) {
            string protocol = get_protocol_for_uri (res.uri);
            res.protocol = protocol;
        }

        /* DLNA related fields */
        res.dlna_profile = "MP3"; /* FIXME */

        if (item.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            res.dlna_flags |= DLNAFlags.INTERACTIVE_TRANSFER_MODE;
        } else {
            res.dlna_flags |= DLNAFlags.STREAMING_TRANSFER_MODE;
        }

        if (res.size > 0) {
            res.dlna_operation = DLNAOperation.RANGE;
            res.dlna_flags |= DLNAFlags.BACKGROUND_TRANSFER_MODE;
        }

        return res;
    }
}
