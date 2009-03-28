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

    public L16Transcoder () {
        var mime_type = "audio/L" + L16Transcoder.WIDTH.to_string () +
                        ";rate=" + L16Transcoder.FREQUENCY.to_string () +
                        ";channels=" + L16Transcoder.CHANNELS.to_string ();

        base (mime_type, "LPCM");
    }

    public override Element create_source (Element src) throws Error {
        return new L16TranscoderBin (src,
                                     L16Transcoder.CHANNELS,
                                     L16Transcoder.FREQUENCY,
                                     L16Transcoder.WIDTH,
                                     L16Transcoder.DEPTH,
                                     L16Transcoder.ENDIANNESS,
                                     L16Transcoder.SIGNED);
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
}
