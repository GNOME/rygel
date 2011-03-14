/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.WMATranscoder : Rygel.Transcoder {
    public const int BITRATE = 64;

    private const string CONVERT_SINK_PAD = "convert-sink-pad";

    public WMATranscoder () {
        base ("audio/x-wma", "WMA", AudioItem.UPNP_CLASS);
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null)
            return null;

        // Convert bitrate to bytes/second
        resource.bitrate = BITRATE * 1000 / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is AudioItem)) {
            return uint.MAX;
        }

        var audio_item = item as AudioItem;
        var distance = uint.MIN;

        if (audio_item.bitrate > 0) {
            distance += (audio_item.bitrate - BITRATE).abs ();
        }

        return distance;
    }

    protected override EncodingProfile get_encoding_profile () {
        var format = Caps.from_string ("video/x-ms-asf");
        // FIXME: We should use the preset to set bitrate
        var encoding_profile = new EncodingAudioProfile (format,
                                                         null,
                                                         null,
                                                         1);

        return encoding_profile;
    }
}
