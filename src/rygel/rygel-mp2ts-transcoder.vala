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

internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    public const string mime_type = "video/mpeg";
    public const string dlna_profile = "MP3";

    private const string DECODEBIN = "decodebin2";
    private const string VIDEO_ENCODER = "mpeg2enc";
    private const string COLORSPACE_CONVERT = "ffmpegcolorspace";
    private const string VIDEO_RATE = "videorate";
    private const string MUXER = "mpegtsmux";

    private const string AUDIO_ENC_SINK = "audio-enc-sink-pad";
    private const string VIDEO_ENC_SINK = "sink";

    private dynamic Element audio_enc;
    private dynamic Element video_enc;
    private dynamic Element muxer;

    public MP2TSTranscoder (Element src) throws Error {
        Element decodebin = ElementFactory.make (DECODEBIN, DECODEBIN);
        if (decodebin == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    DECODEBIN);
        }

        this.audio_enc = MP3Transcoder.create_encoder (MP3Profile.LAYER2,
                                                       null,
                                                       AUDIO_ENC_SINK);

        this.video_enc = MP2TSTranscoder.create_encoder (null,
                                                         VIDEO_ENC_SINK);

        this.muxer = ElementFactory.make (MUXER, MUXER);
        if (muxer == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    MUXER);
        }

        this.add_many (src, decodebin, this.muxer);
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
        if (!audio_enc_pad.is_linked () &&
            this.pads_compatible (new_pad, audio_enc_pad)) {
            encoder = this.audio_enc;
            enc_pad = audio_enc_pad;
        } else if (!video_enc_pad.is_linked () &&
                   this.pads_compatible (new_pad, video_enc_pad)) {
            encoder = this.video_enc;
            enc_pad = video_enc_pad;
        } else {
            return;
        }

        this.add_many (encoder);
        encoder.link (this.muxer);

        if (new_pad.link (enc_pad) != PadLinkReturn.OK) {
            this.post_error (new LiveResponseError.LINK (
                             "Failed to link pad %s to %s",
                             new_pad.name,
                             enc_pad.name));
            return;
        }

        encoder.sync_state_with_parent ();
    }

    internal static Element create_encoder (string? src_pad_name,
                                            string? sink_pad_name)
                                            throws Error {
        var videorate = ElementFactory.make (VIDEO_RATE, VIDEO_RATE);
        if (videorate == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    VIDEO_RATE);
        }

        var convert = ElementFactory.make (COLORSPACE_CONVERT,
                COLORSPACE_CONVERT);
        if (convert == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    COLORSPACE_CONVERT);
        }

        var encoder = ElementFactory.make (VIDEO_ENCODER, VIDEO_ENCODER);
        if (encoder == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    VIDEO_ENCODER);
        }

        var bin = new Bin ("video-encoder-bin");
        bin.add_many (videorate, convert, encoder);

        videorate.link_many (convert, encoder);

        var pad = videorate.get_static_pad ("sink");
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = encoder.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
