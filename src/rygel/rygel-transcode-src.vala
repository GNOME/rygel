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

internal class Rygel.TranscodeSrc : Gst.Bin {
   private const string DECODEBIN = "decodebin2";
   private const string AUDIO_ENCODER = "ffenc_mp2";
   private const string VIDEO_ENCODER = "ffenc_mpeg2video";
   private const string MUXER = "mpegtsmux";

   private dynamic Element audio_enc;
   private dynamic Element video_enc;
   private dynamic Element muxer;

   public TranscodeSrc (Element src) throws Error {
        Element decodebin = ElementFactory.make (DECODEBIN, DECODEBIN);
        if (decodebin == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing", DECODEBIN);
        }

        this.audio_enc = ElementFactory.make (AUDIO_ENCODER, AUDIO_ENCODER);
        if (audio_enc == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    AUDIO_ENCODER);
        }

        this.video_enc = ElementFactory.make (VIDEO_ENCODER, VIDEO_ENCODER);
        if (video_enc == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing",
                                    VIDEO_ENCODER);
        }

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

   private void decodebin_pad_added (Element decodebin,
                                     Pad     new_pad) {
        var encoder = this.audio_enc;

        Pad enc_pad = encoder.get_compatible_pad (new_pad, null);
        if (enc_pad == null) {
            // Try video encoder
            encoder = this.video_enc;
            enc_pad = encoder.get_compatible_pad (new_pad, null);
        }

        if (enc_pad == null) {
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

    private void post_error (Error error) {
        Message msg = new Message.error (this, error, error.message);
        this.post_message (msg);
    }
}
