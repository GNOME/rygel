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
 * This element uses MP2TSTrancoderBin for actual transcoding.
 */
internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    private const int VIDEO_BITRATE = 3000;

    // HD
    private const int[] WIDTH = {640, 1280};
    private const int[] HEIGHT = {480, 720};
    private const string[] PROFILES = {"MPEG_TS_SD_US", "MPEG_TS_HD_US"};
    private const int BITRATE = 3000000;

    private const string VIDEO_ENCODER = "ffenc_mpeg2video";
    private const string COLORSPACE_CONVERT = "ffmpegcolorspace";
    private const string VIDEO_RATE = "videorate";
    private const string VIDEO_SCALE = "videoscale";

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg", PROFILES[profile], MediaItem.VIDEO_CLASS);

        this.profile = profile;
    }

    public override Element create_source (MediaItem item,
                                           Element   src)
                                           throws Error {
        return new MP2TSTranscoderBin (item, src, this);
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
        resource.bitrate = (VIDEO_BITRATE + MP3Transcoder.BITRATE) * 1000 / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (item.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            return uint.MAX;
        }

        uint distance;

        if (item.upnp_class.has_prefix (MediaItem.VIDEO_CLASS)) {
            distance = uint.MIN;

            if (item.bitrate > 0) {
                distance += (item.bitrate - BITRATE).abs ();
            }

            if (item.width > 0) {
                distance += (item.width - WIDTH[this.profile]).abs ();
            }

            if (item.height > 0) {
                distance += (item.height - HEIGHT[this.profile]).abs ();
            }
        } else {
            distance = uint.MAX / 2;
        }

        return distance;
    }

    public Element create_encoder (MediaItem item,
                                   string?   src_pad_name,
                                   string?   sink_pad_name)
                                   throws Error {
        var videorate = GstUtils.create_element (VIDEO_RATE, VIDEO_RATE);
        var videoscale = GstUtils.create_element (VIDEO_SCALE, VIDEO_SCALE);
        var convert = GstUtils.create_element (COLORSPACE_CONVERT,
                                               COLORSPACE_CONVERT);
        dynamic Element encoder = GstUtils.create_element (VIDEO_ENCODER,
                                                           VIDEO_ENCODER);

        encoder.bitrate = (int) VIDEO_BITRATE * 1000;

        var bin = new Bin ("video-encoder-bin");
        bin.add_many (videorate, videoscale, convert, encoder);

        convert.link_many (videoscale, videorate);

        int pixel_w;
        int pixel_h;

        if (item.pixel_width > 0 && item.pixel_height > 0) {
            pixel_w = item.width * HEIGHT[this.profile] * item.pixel_width;
            pixel_h = item.height * WIDTH[this.profile] * item.pixel_height;
        } else {
            // Original pixel-ratio not provided, lets just use 1:1
            pixel_w = 1;
            pixel_h = 1;
        }

        var caps = new Caps.simple ("video/x-raw-yuv",
                                    "width",
                                        typeof (int),
                                        WIDTH[this.profile],
                                    "height",
                                        typeof (int),
                                        HEIGHT[this.profile],
                                    "framerate",
                                        typeof (Fraction),
                                        30,
                                        1,
                                    "pixel-aspect-ratio",
                                        typeof (Fraction),
                                        pixel_w,
                                        pixel_h);
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
