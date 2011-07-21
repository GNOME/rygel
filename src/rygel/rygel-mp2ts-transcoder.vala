/*
 * Copyright (C) 2009 Nokia Corporation.
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
using Gst;
using GUPnP;
using Gee;

internal enum Rygel.MP2TSProfile {
    SD = 0,
    HD
}

/**
 * Transcoder for mpeg transport stream containing mpeg 2 video and mp2 audio.
 */
internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    private const int VIDEO_BITRATE = 3000;
    private const int AUDIO_BITRATE = 256;

    // HD
    private const int[] WIDTH = {720, 1280};
    private const int[] HEIGHT = {576, 720};
    private const int[] FRAME_RATE = {25, 30};
    private const string[] PROFILES = {"MPEG_TS_SD_EU_ISO", "MPEG_TS_HD_NA_ISO"};
    private const int BITRATE = 3000000;

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg", PROFILES[profile], VideoItem.UPNP_CLASS);

        this.profile = profile;
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null)
            return null;

        resource.width = WIDTH[profile];
        resource.height = HEIGHT[profile];
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

        if (video_item.width > 0) {
            distance += (video_item.width - WIDTH[this.profile]).abs ();
        }

        if (video_item.height > 0) {
            distance += (video_item.height - HEIGHT[this.profile]).abs ();
        }

        return distance;
    }

    protected override EncodingProfile get_encoding_profile () {
        var cont_format = Caps.from_string ("video/mpegts," +
                                            "systemstream=true," +
                                            "packetsize=188");
        var framerate = "framerate=(fraction)%d/1".printf
                                        (FRAME_RATE[this.profile]);

        var video_format = Caps.from_string ("video/mpeg," +
                                             "mpegversion=2," +
                                             "systemstream=false," +
                                             framerate);
        var restriction = "video/x-raw-yuv," +
                          framerate + "," +
                          "width=%d,".printf (HEIGHT[this.profile]) +
                          "height=%d".printf (WIDTH[this.profile]);

        var video_restriction = Caps.from_string (restriction);

        var audio_format = Caps.from_string ("audio/mpeg," +
                                             "mpegversion=1," +
                                             "layer=2");

        var enc_container_profile = new EncodingContainerProfile ("container",
                                                                  null,
                                                                  cont_format,
                                                                  null);
        var enc_video_profile = new EncodingVideoProfile (video_format,
                                                          null,
                                                          video_restriction,
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
