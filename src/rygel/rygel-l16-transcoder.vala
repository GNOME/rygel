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

internal class Rygel.L16Transcoder : Rygel.Transcoder {
    public const int channels = 2;
    public const int frequency = 44100;
    public const int width = 16;
    public const int depth = 16;
    public const int endianness = ByteOrder.BIG_ENDIAN; // Network byte order

    public const string mime_type = "audio/L16;rate=44100;channels=2";
    public const string dlna_profile = "LPCM";

    private const string DECODEBIN = "decodebin2";
    private const string AUDIO_CONVERT = "audioconvert";
    private const string AUDIO_RESAMPLE = "audioresample";
    private const string CAPS_FILTER = "capsfilter";

    private const string AUDIO_SRC_PAD = "audio-src-pad";
    private const string AUDIO_SINK_PAD = "audio-sink-pad";

    private dynamic Element audio_enc;

    public L16Transcoder (Element src) throws Error {
        Element decodebin = Transcoder.create_element (DECODEBIN, DECODEBIN);

        this.audio_enc = L16Transcoder.create_encoder (AUDIO_SRC_PAD,
                                                       AUDIO_SINK_PAD);

        this.add_many (src, decodebin, this.audio_enc);
        src.link (decodebin);

        var src_pad = this.audio_enc.get_static_pad (AUDIO_SRC_PAD);
        var ghost = new GhostPad (null, src_pad);
        this.add_pad (ghost);

        decodebin.pad_added += this.decodebin_pad_added;
    }

    private void decodebin_pad_added (Element decodebin, Pad new_pad) {
        Pad enc_pad = this.audio_enc.get_pad (AUDIO_SINK_PAD);
        if (enc_pad.is_linked () || !this.pads_compatible (new_pad, enc_pad)) {
            return;
        }

        if (new_pad.link (enc_pad) != PadLinkReturn.OK) {
            this.post_error (new LiveResponseError.LINK (
                                        "Failed to link pad %s to %s",
                                        new_pad.name,
                                        enc_pad.name));
            return;
        }

        this.audio_enc.sync_state_with_parent ();
    }

    internal static Element create_encoder (string?    src_pad_name,
                                            string?    sink_pad_name)
                                            throws Error {
        dynamic Element convert1 = Transcoder.create_element (AUDIO_CONVERT,
                                                             null);
        dynamic Element resample = Transcoder.create_element (AUDIO_RESAMPLE,
                                                              AUDIO_RESAMPLE);
        dynamic Element convert2 = Transcoder.create_element (AUDIO_CONVERT,
                                                              null);
        dynamic Element capsfilter = Transcoder.create_element (CAPS_FILTER,
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
                                    "signed", typeof (bool), true);

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
