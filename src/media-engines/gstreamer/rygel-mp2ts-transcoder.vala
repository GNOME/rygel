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

internal enum Rygel.MP2TSProfile {
    SD_EU = 0,
    SD_NA,
    HD_NA,
}

/**
 * Transcoder for mpeg transport stream containing mpeg 2 video and mp2 audio.
 */
internal class Rygel.MP2TSTranscoder : Rygel.VideoTranscoder {
    private const int VIDEO_BITRATE = 1500;
    private const int AUDIO_BITRATE = 192;

    // HD
    private const int[] WIDTH = {720, 720, 1280};
    private const int[] HEIGHT = {576, 480, 720};
    private const int[] FRAME_RATE = {25, 30, 30};
    private const string[] PROFILES = {"MPEG_TS_SD_EU_ISO",
                                       "MPEG_TS_SD_NA_ISO",
                                       "MPEG_TS_HD_NA_ISO"};

    private const string CONTAINER =
        "video/mpegts,systemstream=true,packetsize=188";

    private const string AUDIO_FORMAT =
        "audio/mpeg,mpegversion=1,layer=2";

    private const string BASE_VIDEO_FORMAT =
        "video/mpeg,mpegversion=2,systemstream=false";

    private const string RESTRICTION_TEMPLATE =
        "video/x-raw,framerate=(fraction)%d/1,width=%d,height=%d";

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg",
              PROFILES[profile],
              AUDIO_BITRATE,
              VIDEO_BITRATE,
              CONTAINER,
              AUDIO_FORMAT,
              BASE_VIDEO_FORMAT,
              "mpg",
              RESTRICTION_TEMPLATE.printf (FRAME_RATE[profile],
                                           WIDTH[profile],
                                           HEIGHT[profile]));

        this.profile = profile;
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaFileItem    item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null) {
            return null;
        }

        resource.width = WIDTH[this.profile];
        resource.height = HEIGHT[this.profile];
        resource.bitrate = (VIDEO_BITRATE + AUDIO_BITRATE) * 1000 / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is VideoItem)) {
            return uint.MAX;
        }

        var video_item = item as VideoItem;
        var distance = base.get_distance (item);

        if (video_item.bitrate > 0) {
            distance += (video_item.bitrate - VIDEO_BITRATE).abs ();
        }

        if (video_item.width > 0) {
            distance += (video_item.width - WIDTH[this.profile]).abs ();
        }

        if (video_item.height > 0) {
            distance += (video_item.height - HEIGHT[this.profile]).abs ();
        }

        return distance;
    }
}
