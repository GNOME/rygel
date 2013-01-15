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

/**
 * Represents an audio item.
 */
public class Rygel.AudioItem : MediaItem {
    public new const string UPNP_CLASS = "object.item.audioItem";

    public long duration { get; set; default = -1; }  // Duration in seconds
    public int bitrate { get; set; default = -1; }    // Bytes/second

    public int sample_freq { get; set; default = -1; }
    public int bits_per_sample { get; set; default = -1; }
    public int channels { get; set; default = -1; }

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
