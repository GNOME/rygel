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

internal class Rygel.MP3Transcoder : Rygel.Transcoder {
    private const string AUDIO_CONVERT = "audioconvert";
    private const string[] AUDIO_ENCODER = {null, "twolame", "lame"};
    private const string AUDIO_PARSER = "mp3parse";
    private const string AUDIO_RESAMPLE = "audioresample";

    private MP3Layer layer;

    public MP3Transcoder (MP3Layer layer) {
        base ("audio/mpeg", "MP3");

        this.layer = layer;
    }

    public override Element create_source (Element src) throws Error {
        return new MP3TranscoderBin (src, this);
    }

    public Element create_encoder (string?  src_pad_name,
                                   string?  sink_pad_name)
                                   throws Error {
        dynamic Element convert = GstUtils.create_element (AUDIO_CONVERT,
                                                           AUDIO_CONVERT);
        dynamic Element resample = GstUtils.create_element (AUDIO_RESAMPLE,
                                                            AUDIO_RESAMPLE);
        dynamic Element encoder = GstUtils.create_element (
                                                    AUDIO_ENCODER[this.layer],
                                                    AUDIO_ENCODER[this.layer]);
        dynamic Element parser = GstUtils.create_element (AUDIO_PARSER,
                                                          AUDIO_PARSER);

        if (this.layer == MP3Layer.THREE) {
            // Best quality
            encoder.quality = 0;
        }

        encoder.bitrate = 256;

        var bin = new Bin ("audio-encoder-bin");
        bin.add_many (convert, resample, encoder, parser);

        var filter = Caps.from_string ("audio/x-raw-int");
        convert.link_filtered (encoder, filter);
        encoder.link (parser);

        var pad = convert.get_static_pad ("sink");
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = parser.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
