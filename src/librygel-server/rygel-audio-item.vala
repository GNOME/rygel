/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
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

/**
 * Represents an audio item contained in a file.
 */
public class Rygel.AudioItem : MediaFileItem {
    public new const string UPNP_CLASS = "object.item.audioItem";

    /**
     * The duration of the source content (this.uri) in seconds.
     * A value of -1 means the duration is unknown
     */
    public long duration { get; set; default = -1; }

    /**
     * The bitrate of the source content (this.uri) in bytes/second.
     * A value of -1 means the bitrate is unknown
     */
    public int bitrate { get; set; default = -1; }

    /**
     * The sample frequency of the source content (this.uri) in Hz.
     * A value of -1 means the sample frequency is unknown
     */
    public int sample_freq { get; set; default = -1; }

    /**
     * The bits per sample of the source content (this.uri).
     * A value of -1 means the bits per sample is unknown
     */
    public int bits_per_sample { get; set; default = -1; }

    /**
     * The number of audio channels in the source content (this.uri).
     * A value of -1 means the number of channels is unknown
     */
    public int channels { get; set; default = -1; }

    public string album { get; set; }

    public AudioItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = AudioItem.UPNP_CLASS) {
        Object (id : id,
                parent : parent,
                title : title,
                upnp_class : upnp_class);
    }

    public override bool streamable () {
        return true;
    }

    internal override void apply_didl_lite (DIDLLiteObject didl_object) {
        base.apply_didl_lite (didl_object);

        this.album = didl_object.album;
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        if (!(media_object is AudioItem)) {
            return 1;
        }

        var item = media_object as AudioItem;
        switch (property) {
        case "upnp:album":
            return this.compare_string_props (this.album, item.album);
        default:
            return base.compare_by_property (item, property);
        }
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer http_server)
                                                 throws Error {
        var didl_item = base.serialize (serializer, http_server);

        if (this.album != null && this.album != "") {
            didl_item.album = this.album;
        }

        return didl_item;
    }

    internal override DIDLLiteResource add_resource
                                        (DIDLLiteObject didl_object,
                                         string?        uri,
                                         string         protocol,
                                         string?        import_uri = null)
                                         throws Error {
        var res = base.add_resource (didl_object, uri, protocol, import_uri);

        res.duration = this.duration;
        res.bitrate = this.bitrate;
        res.sample_freq = this.sample_freq;
        res.bits_per_sample = this.bits_per_sample;
        res.audio_channels = this.channels;

        return res;
    }
}
