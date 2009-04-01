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
using Rygel;
using Gst;
using GUPnP;

internal enum Rygel.MP2TSProfile {
    SD = 0,
    HD
}

/**
 * Transcoder for mpeg transport stream containing mpeg 2 video and mp2 audio.
 * This element uses MP2TSTrancoderBin for actual transcoding.
 */
internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    // HD
    private const int[] WIDTH = {640, 1920};
    private const int[] HEIGHT = {480, 1080};
    private const string[] PROFILES = {"MPEG_TS_SD_US", "MPEG_TS_HD_US"};

    private const string VIDEO_ENCODER = "ffenc_mpeg2video";
    private const string COLORSPACE_CONVERT = "ffmpegcolorspace";
    private const string VIDEO_RATE = "videorate";
    private const string VIDEO_SCALE = "videoscale";

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg", PROFILES[profile], MediaItem.VIDEO_CLASS);

        this.profile = profile;
    }

    public override Element create_source (Element src) throws Error {
        return new MP2TSTranscoderBin (src, this);
    }

    public override DIDLLiteResource create_resource (MediaItem        item,
                                                      TranscodeManager manager)
                                                      throws Error {
        var res = base.create_resource (item, manager);

        res.width = WIDTH[profile];
        res.height = HEIGHT[profile];

        return res;
    }

    public Element create_encoder (string? src_pad_name,
                                   string? sink_pad_name)
                                   throws Error {
        var videorate = GstUtils.create_element (VIDEO_RATE, VIDEO_RATE);
        var videoscale = GstUtils.create_element (VIDEO_SCALE, VIDEO_SCALE);
        var convert = GstUtils.create_element (COLORSPACE_CONVERT,
                                               COLORSPACE_CONVERT);
        var encoder = GstUtils.create_element (VIDEO_ENCODER, VIDEO_ENCODER);

        var bin = new Bin ("video-encoder-bin");
        bin.add_many (videorate, videoscale, convert, encoder);

        convert.link_many (videoscale, videorate);
        var caps = new Caps.simple (
                                "video/x-raw-yuv",
                                "width", typeof (int), WIDTH[this.profile],
                                "height", typeof (int), HEIGHT[this.profile],
                                "framerate", typeof (Fraction), 30, 1,
                                "pixel-aspect-ratio", typeof (Fraction), 1, 1);
        videorate.link_filtered (encoder, caps);

        var pad = convert.get_static_pad ("sink");
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = encoder.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
