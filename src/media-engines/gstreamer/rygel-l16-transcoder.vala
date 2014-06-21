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

/**
 * Transcoder for linear PCM audio (LPCM).
 */
internal class Rygel.L16Transcoder : Rygel.AudioTranscoder {
    private const int CHANNELS = 2;
    private const int FREQUENCY = 44100;
    private const int WIDTH = 16;
    private const int DEPTH = 16;
    private const bool SIGNED = true;
    private const int ENDIANNESS = ByteOrder.BIG_ENDIAN;

    public L16Transcoder () {
        var mime_type = "audio/L" + L16Transcoder.WIDTH.to_string () +
                        ";rate=" + L16Transcoder.FREQUENCY.to_string () +
                        ";channels=" + L16Transcoder.CHANNELS.to_string ();

        var caps_str = "audio/x-raw,format=S16BE" +
                       ",channels=" + CHANNELS.to_string () +
                       ",rate=" +  FREQUENCY.to_string ();

        base (mime_type,
              "LPCM",
              0,
              AudioTranscoder.NO_CONTAINER,
              caps_str,
              "lpcm");
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaFileItem    item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null) {
            return null;
        }

        resource.sample_freq = L16Transcoder.FREQUENCY;
        resource.audio_channels = L16Transcoder.CHANNELS;
        resource.bits_per_sample = L16Transcoder.WIDTH;
        // Set bitrate in bytes/second
        resource.bitrate = L16Transcoder.FREQUENCY *
                           L16Transcoder.CHANNELS *
                           L16Transcoder.WIDTH / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is AudioItem) || item is VideoItem) {
            return uint.MAX;
        }

        var audio_item = item as AudioItem;
        var distance = uint.MIN;

        if (audio_item.sample_freq > 0) {
            distance += (audio_item.sample_freq - FREQUENCY).abs ();
        }

        if (audio_item.channels > 0) {
            distance += (audio_item.channels - CHANNELS).abs ();
        }

        if (audio_item.bits_per_sample > 0) {
            distance += (audio_item.bits_per_sample - WIDTH).abs ();
        }

        return distance;
    }
}
