/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

private errordomain Rygel.MediaItemError {
    BAD_URI
}

/**
 * Represents a media (Music, Video and Image) item.
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

    // Resource info
    public ArrayList<string> uris;
    public string mime_type;

    public long size = -1;       // Size in bytes
    public long duration = -1;   // Duration in seconds
    public int bitrate = -1;     // Bytes/second

    // Audio/Music
    public int sample_freq = -1;
    public int bits_per_sample = -1;
    public int n_audio_channels = -1;
    public int track_number = -1;

    // Image/Video
    public int width = -1;
    public int height = -1;
    public int color_depth = -1;

    public MediaItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class) {
        this.id = id;
        this.parent = parent;
        this.title = title;
        this.upnp_class = upnp_class;

        this.uris = new ArrayList<string> ();
    }

    // Live media items need to provide a nice working implementation of this
    // method if they can/do no provide a valid URI
    public virtual Gst.Element? create_stream_source () {
        return null;
    }

    internal DIDLLiteResource create_res (string uri) throws Error {
        DIDLLiteResource res = DIDLLiteResource ();
        res.reset ();

        res.uri = uri;
        res.mime_type = this.mime_type;

        res.size = this.size;
        res.duration = this.duration;
        res.bitrate = this.bitrate;

        res.sample_freq = this.sample_freq;
        res.bits_per_sample = this.bits_per_sample;
        res.n_audio_channels = this.n_audio_channels;

        res.width = this.width;
        res.height = this.height;
        res.color_depth = this.color_depth;

        /* Protocol info */
        if (res.uri != null) {
            string protocol = get_protocol_for_uri (res.uri);
            res.protocol = protocol;
        }

        if (this.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
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

    private string get_protocol_for_uri (string uri) throws Error {
        if (uri.has_prefix ("http")) {
            return "http-get";
        } else if (uri.has_prefix ("file")) {
            return "internal";
        } else if (uri.has_prefix ("rtsp")) {
            // FIXME: Assuming that RTSP is always accompanied with RTP over UDP
            return "rtsp-rtp-udp";
        } else {
            warning ("Failed to probe protocol for URI %s", uri);

            // Assume the protocol to be the scheme of the URI
            var tokens = uri.split (":", 2);
            if (tokens[0] == null) {
                throw new MediaItemError.BAD_URI ("Bad URI: %s", uri);
            }

            return tokens[0];
        }
    }
}
