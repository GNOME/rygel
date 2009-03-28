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

internal class Rygel.L16TranscoderBin : Rygel.TranscoderBin {
    private const string DECODEBIN = "decodebin2";
    private const string AUDIO_CONVERT = "audioconvert";
    private const string AUDIO_RESAMPLE = "audioresample";
    private const string CAPS_FILTER = "capsfilter";

    private const string AUDIO_SRC_PAD = "audio-src-pad";
    private const string AUDIO_SINK_PAD = "audio-sink-pad";

    private dynamic Element audio_enc;

    public L16TranscoderBin (Element src,
                             int     channels,
                             int     frequency,
                             int     width,
                             int     depth,
                             int     endianness,
                             bool    signed_)
                             throws Error {
        Element decodebin = TranscoderBin.create_element (DECODEBIN, DECODEBIN);

        this.audio_enc = L16TranscoderBin.create_encoder (AUDIO_SRC_PAD,
                                                          AUDIO_SINK_PAD,
                                                          channels,
                                                          frequency,
                                                          width,
                                                          depth,
                                                          endianness,
                                                          signed_);

        this.add_many (src, decodebin, this.audio_enc);
        src.link (decodebin);

        var src_pad = this.audio_enc.get_static_pad (AUDIO_SRC_PAD);
        var ghost = new GhostPad (null, src_pad);
        this.add_pad (ghost);

        decodebin.pad_added += this.decodebin_pad_added;
    }

    private void decodebin_pad_added (Element decodebin, Pad new_pad) {
        Pad enc_pad = this.audio_enc.get_pad (AUDIO_SINK_PAD);
        if (!new_pad.can_link (enc_pad)) {
            return;
        }

        if (new_pad.link (enc_pad) != PadLinkReturn.OK) {
            this.post_error (new LiveResponseError.LINK (
                                        "Failed to link pad %s to %s",
                                        new_pad.name,
                                        enc_pad.name));
            return;
        }
    }

    public static Element create_encoder (string? src_pad_name,
                                          string? sink_pad_name,
                                          int     channels,
                                          int     frequency,
                                          int     width,
                                          int     depth,
                                          int     endianness,
                                          bool    signed_)
                                          throws Error {
        dynamic Element convert1 = TranscoderBin.create_element (AUDIO_CONVERT,
                                                                 null);
        dynamic Element resample = TranscoderBin.create_element (
                                                        AUDIO_RESAMPLE,
                                                        AUDIO_RESAMPLE);
        dynamic Element convert2 = TranscoderBin.create_element (AUDIO_CONVERT,
                                                                 null);
        dynamic Element capsfilter = TranscoderBin.create_element (CAPS_FILTER,
                                                                   CAPS_FILTER);

        var bin = new Bin ("audio-encoder-bin");
        bin.add_many (convert1, resample, convert2, capsfilter);

        capsfilter.caps = new Caps.simple (
                                    "audio/x-raw-int",
                                    "channels", typeof (int), channels,
                                    "rate",  typeof (int), frequency,
                                    "width", typeof (int), width,
                                    "depth", typeof (int), depth,
                                    "endianness", typeof (int), endianness,
                                    "signed", typeof (bool), signed_);

        convert1.link_many (resample, convert2, capsfilter);

        var pad = convert1.get_static_pad ("sink");
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = capsfilter.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
