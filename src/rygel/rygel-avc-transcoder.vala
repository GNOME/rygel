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

internal class Rygel.AVCTranscoder : Rygel.Transcoder {
    private const int BITRATE = 1200000;
    private const int VIDEO_BITRATE = 1200;
    private const int AUDIO_BITRATE = 64;

    public AVCTranscoder () {
        base ("video/mp4", "AVC_MP4_BL_CIF15_AAC_520", VideoItem.UPNP_CLASS);
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null) {
            return null;
        }

        var video_item = item as VideoItem;

        resource.width = video_item.width;
        resource.height = video_item.height;
        resource.bitrate = (VIDEO_BITRATE + AUDIO_BITRATE) * 1000 / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is VideoItem)) {
            return uint.MAX;
        }

        var video_item = item as VideoItem;
        var distance = uint.MIN;

        if (video_item.bitrate > 0) {
            distance += (video_item.bitrate - BITRATE).abs ();
        }

        return distance;
    }

    protected override EncodingProfile get_encoding_profile () {
        var container_format = Caps.from_string ("video/quicktime,variant=iso");

        var video_format = Caps.from_string ("video/x-h264,stream-format=avc");
        var audio_format = Caps.from_string ("audio/mpeg,mpegversion=4");

        var enc_container_profile = new EncodingContainerProfile("container",
                                                                 null,
                                                                 container_format,
                                                                 null);
        var enc_video_profile = new EncodingVideoProfile (video_format,
                                                          null,
                                                          null,
                                                          1);
        var enc_audio_profile = new EncodingAudioProfile (audio_format,
                                                          null,
                                                          null,
                                                          1);

        // FIXME: We should use the preset to set bitrate
        enc_container_profile.add_profile (enc_video_profile);
        enc_container_profile.add_profile (enc_audio_profile);

        return enc_container_profile;
    }
}
