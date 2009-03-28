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

/**
 * A Gst.Bin derivative that implements transcoding of any type of media (using
 * decodebin2) to mpeg transport stream containing mpeg 2 video and mp2 audio.
 */
internal class Rygel.MP2TSTranscoderBin : Gst.Bin {
    private const string DECODEBIN = "decodebin2";
    private const string MUXER = "mpegtsmux";

    private const string AUDIO_ENC_SINK = "audio-enc-sink-pad";
    private const string VIDEO_ENC_SINK = "sink";

    private dynamic Element audio_enc;
    private dynamic Element video_enc;
    private dynamic Element muxer;

    public MP2TSTranscoderBin (Element         src,
                               MP2TSTranscoder transcoder)
                               throws Error {
        Element decodebin = GstUtils.create_element (DECODEBIN, DECODEBIN);
        var mp3_transcoder = new MP3Transcoder (MP3Layer.TWO);
        this.audio_enc = mp3_transcoder.create_encoder (null,
                                                        AUDIO_ENC_SINK);
        this.video_enc = transcoder.create_encoder (null, VIDEO_ENC_SINK);
        this.muxer = GstUtils.create_element (MUXER, MUXER);

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
            GstUtils.post_error (this,
                                 new LiveResponseError.LINK (
                                                "Failed to link pad %s to %s",
                                                new_pad.name,
                                                enc_pad.name));
            return;
        }
    }
}
