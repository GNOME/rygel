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

internal class Rygel.L16Transcoder : Rygel.Transcoder {
    private const int CHANNELS = 2;
    private const int FREQUENCY = 44100;
    private const int WIDTH = 16;
    private const int DEPTH = 16;
    private const int ENDIANNESS = ByteOrder.BIG_ENDIAN; // Network byte order
    private const bool SIGNED = true; // Network byte order

    private const string AUDIO_CONVERT = "audioconvert";
    private const string AUDIO_RESAMPLE = "audioresample";
    private const string CAPS_FILTER = "capsfilter";

    public L16Transcoder () {
        var mime_type = "audio/L" + L16Transcoder.WIDTH.to_string () +
                        ";rate=" + L16Transcoder.FREQUENCY.to_string () +
                        ";channels=" + L16Transcoder.CHANNELS.to_string ();

        base (mime_type, "LPCM");
    }

    public override Element create_source (Element src) throws Error {
        return new L16TranscoderBin (src, this);
    }

    public override DIDLLiteResource create_resource (
                                        MediaItem        item,
                                        TranscodeManager manager)
                                        throws Error {
        var res = base.create_resource (item, manager);

        res.sample_freq = L16Transcoder.FREQUENCY;
        res.n_audio_channels = L16Transcoder.CHANNELS;
        res.bits_per_sample = L16Transcoder.WIDTH;

        return res;
    }

    public Element create_encoder (string? src_pad_name,
                                   string? sink_pad_name)
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
                                    "channels", typeof (int), CHANNELS,
                                    "rate",  typeof (int), FREQUENCY,
                                    "width", typeof (int), WIDTH,
                                    "depth", typeof (int), DEPTH,
                                    "endianness", typeof (int), ENDIANNESS,
                                    "signed", typeof (bool), SIGNED);

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
