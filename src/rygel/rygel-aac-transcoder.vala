/*
 * Copyright (C) 2011 Nokia Corporation.
 *
 * Author: Luis de Bethencourt <luis.debethencourt@collabora.com>
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

internal enum Rygel.AACProfile {
    SD = 0,
    HD
}

/**
 * Transcoder for aac stream containing mpeg 4 audio.
 */
internal class Rygel.AACTranscoder : Rygel.Transcoder {
    private const int BITRATE = 256;

    public AACTranscoder () {
        base ("audio/3gpp", "AAC_ISO_320", AudioItem.UPNP_CLASS);
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null) {
            return null;
        }

        resource.bitrate = (BITRATE * 1000) / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is AudioItem) || item is VideoItem) {
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
        var container_format = Caps.from_string ("application/x-3gp,profile=basic");
        var audio_format = Caps.from_string ("audio/mpeg," +
                                             "mpegversion=4," +
                                             "framed=true," +
                                             "stream-format=raw," +
                                       /*    "level=2," + */
                                             "profile=lc," +
                                             "codec_data=1208,rate=44100,channels=1");
        var enc_container_profile = new EncodingContainerProfile ("container",
                                                                  null,
                                                                  container_format,
                                                                  null);
        var enc_audio_profile = new EncodingAudioProfile (audio_format,
                                                          null,
                                                          null,
                                                          1);

        enc_container_profile.add_profile (enc_audio_profile);

        return enc_container_profile;
    }
}
