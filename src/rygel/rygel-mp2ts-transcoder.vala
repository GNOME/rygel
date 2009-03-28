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
using Gee;

internal enum Rygel.MP2TSProfile {
    SD = 0,
    HD
}

internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    // HD
    private const int[] WIDTH = {640, 1920};
    private const int[] HEIGHT = {480, 1080};
    private const string[] PROFILES = {"MPEG_TS_SD_NA", "MPEG_TS_HD_NA"};

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg", PROFILES[profile]);

        this.profile = profile;
    }

    public override Element create_source (Element src) throws Error {
        return new MP2TSTranscoderBin (src,
                                       MP2TSTranscoder.WIDTH[this.profile],
                                       MP2TSTranscoder.HEIGHT[this.profile]);
    }

    public override DIDLLiteResource create_resource (MediaItem        item,
                                                      TranscodeManager manager)
                                                      throws Error {
        var res = base.create_resource (item, manager);

        res.width = WIDTH[profile];
        res.height = HEIGHT[profile];

        return res;
    }
}

private class Rygel.MP2TSTranscoderBin : Rygel.TranscoderBin {
    private const string DECODEBIN = "decodebin2";
    private const string VIDEO_ENCODER = "mpeg2enc";
    private const string COLORSPACE_CONVERT = "ffmpegcolorspace";
    private const string VIDEO_RATE = "videorate";
    private const string VIDEO_SCALE = "videoscale";
    private const string MUXER = "mpegtsmux";

    private const string AUDIO_ENC_SINK = "audio-enc-sink-pad";
    private const string VIDEO_ENC_SINK = "sink";

    private dynamic Element audio_enc;
    private dynamic Element video_enc;
    private dynamic Element muxer;

    public MP2TSTranscoderBin (Element src,
                               int     width,
                               int     height)
                               throws Error {
        var mp3_transcoder = new MP3Transcoder (MP3Layer.TWO);

        Element decodebin = TranscoderBin.create_element (DECODEBIN, DECODEBIN);
        this.audio_enc = mp3_transcoder.create_encoder (null,
                                                        AUDIO_ENC_SINK);
        this.video_enc = MP2TSTranscoderBin.create_encoder (null,
                                                            VIDEO_ENC_SINK,
                                                            width,
                                                            height);
        this.muxer = TranscoderBin.create_element (MUXER, MUXER);

        this.add_many (src,
                       decodebin,
                       this.audio_enc,
                       this.video_enc,
                       this.muxer);
        src.link (decodebin);

        var src_pad = muxer.get_static_pad ("src");
        var ghost = new GhostPad (null, src_pad);
        this.add_pad (ghost);

        decodebin.pad_added += this.decodebin_pad_added;
    }

    private void decodebin_pad_added (Element decodebin, Pad new_pad) {
        Element encoder;
        Pad enc_pad;

        var audio_enc_pad = this.audio_enc.get_pad (AUDIO_ENC_SINK);
        var video_enc_pad = this.video_enc.get_pad (VIDEO_ENC_SINK);

        // Check which encoder to use
        if (new_pad.can_link (audio_enc_pad)) {
            encoder = this.audio_enc;
            enc_pad = audio_enc_pad;
        } else if (new_pad.can_link (video_enc_pad)) {
            encoder = this.video_enc;
            enc_pad = video_enc_pad;
        } else {
            return;
        }

        encoder.link (this.muxer);

        if (new_pad.link (enc_pad) != PadLinkReturn.OK) {
            this.post_error (new LiveResponseError.LINK (
                             "Failed to link pad %s to %s",
                             new_pad.name,
                             enc_pad.name));
            return;
        }
    }

    internal static Element create_encoder (string? src_pad_name,
                                            string? sink_pad_name,
                                            int     width,
                                            int     height)
                                            throws Error {
        var videorate = TranscoderBin.create_element (VIDEO_RATE, VIDEO_RATE);
        var videoscale = TranscoderBin.create_element (VIDEO_SCALE,
                                                       VIDEO_SCALE);
        var convert = TranscoderBin.create_element (COLORSPACE_CONVERT,
                                                    COLORSPACE_CONVERT);
        var encoder = TranscoderBin.create_element (VIDEO_ENCODER,
                                                    VIDEO_ENCODER);

        var bin = new Bin ("video-encoder-bin");
        bin.add_many (videorate, videoscale, convert, encoder);

        var caps = new Caps.simple ("video/x-raw-yuv",
                                    "width", typeof (int), width,
                                    "height", typeof (int), height);
        videorate.link (convert);
        convert.link (videoscale);
        videoscale.link_filtered (encoder, caps);

        var pad = videorate.get_static_pad ("sink");
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = encoder.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
