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

internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    public const string mime_type = "video/mpeg";
    private const string dlna_profile = "MP3";

    private const string DECODEBIN = "decodebin2";
    private const string VIDEO_ENCODER = "mpeg2enc";
    private const string COLORSPACE_CONVERT = "ffmpegcolorspace";
    private const string VIDEO_RATE = "videorate";
    private const string VIDEO_SCALE = "videoscale";
    private const string MUXER = "mpegtsmux";

    private const string AUDIO_ENC_SINK = "audio-enc-sink-pad";
    private const string VIDEO_ENC_SINK = "sink";

    // HD
    private const int WIDTH = 1920;
    private const int HEIGHT = 1080;

    private dynamic Element audio_enc;
    private dynamic Element video_enc;
    private dynamic Element muxer;

    public MP2TSTranscoder (Element src) throws Error {
        Element decodebin = Transcoder.create_element (DECODEBIN, DECODEBIN);
        this.audio_enc = MP3Transcoder.create_encoder (MP3Profile.LAYER2,
                                                       null,
                                                       AUDIO_ENC_SINK);
        this.video_enc = MP2TSTranscoder.create_encoder (null,
                                                         VIDEO_ENC_SINK);
        this.muxer = Transcoder.create_element (MUXER, MUXER);

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

    public static void add_resources (ArrayList<DIDLLiteResource?> resources,
                                      MediaItem                    item,
                                      TranscodeManager             manager)
                                      throws Error {
        if (Transcoder.mime_type_is_a (item.mime_type,
                                       MP2TSTranscoder.mime_type)) {
            return;
        }

        var res = manager.create_resource (item,
                                           MP2TSTranscoder.mime_type,
                                           MP2TSTranscoder.dlna_profile);
        res.width = WIDTH;
        res.height = HEIGHT;

        resources.add (res);
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
                                            string? sink_pad_name)
                                            throws Error {
        var videorate = Transcoder.create_element (VIDEO_RATE, VIDEO_RATE);
        var videoscale = Transcoder.create_element (VIDEO_SCALE, VIDEO_SCALE);
        var convert = Transcoder.create_element (COLORSPACE_CONVERT,
                                                 COLORSPACE_CONVERT);
        var encoder = Transcoder.create_element (VIDEO_ENCODER, VIDEO_ENCODER);

        var bin = new Bin ("video-encoder-bin");
        bin.add_many (videorate, videoscale, convert, encoder);

        var caps = new Caps.simple ("video/x-raw-yuv",
                                    "width", typeof (int), WIDTH,
                                    "height", typeof (int), HEIGHT);
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

    internal static bool can_handle (string mime_type) {
        return mime_type == MP2TSTranscoder.mime_type;
    }
}
