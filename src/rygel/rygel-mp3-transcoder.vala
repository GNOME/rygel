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
 * Transcoder for mpeg 1 layer 2 and 3 audio. This element uses MP3TrancoderBin
 * for actual transcoding.
 */
internal class Rygel.MP3Transcoder : Rygel.Transcoder {
    public const int BITRATE = 256;

    private const string[] AUDIO_ENCODER = {null, "twolame", "lame"};
    private const string AUDIO_PARSER = "mp3parse";

    private const string CONVERT_SINK_PAD = "convert-sink-pad";

    private MP3Layer layer;

    public MP3Transcoder (MP3Layer layer) {
        base ("audio/mpeg", "MP3", AudioItem.UPNP_CLASS);

        this.layer = layer;
    }

    public override Element create_source (MediaItem item,
                                           Element   src)
                                           throws Error {
        return new MP3TranscoderBin (item, src, this);
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null)
            return null;

        // Convert bitrate to bytes/second
        resource.bitrate = BITRATE * 1000 / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is AudioItem) || item is VideoItem) {
            return uint.MAX;
        }

        var audio_item = item as AudioItem;
        var distance = uint.MIN;

        if (audio_item.bitrate > 0) {
            distance += (audio_item.bitrate - BITRATE).abs ();
        }

        return distance;
    }

    public Element create_encoder (MediaItem item,
                                   string?   src_pad_name,
                                   string?   sink_pad_name)
                                   throws Error {
        var l16_transcoder = new L16Transcoder (Endianness.LITTLE);
        dynamic Element convert = l16_transcoder.create_encoder
                                        (item, null, CONVERT_SINK_PAD);
        dynamic Element encoder = GstUtils.create_element
                                        (AUDIO_ENCODER[this.layer],
                                         AUDIO_ENCODER[this.layer]);
        dynamic Element parser = GstUtils.create_element (AUDIO_PARSER,
                                                          AUDIO_PARSER);

        if (this.layer == MP3Layer.THREE) {
            // Best quality
            encoder.quality = 0;
        }

        encoder.bitrate = BITRATE;

        var bin = new Bin ("mp3-encoder-bin");
        bin.add_many (convert, encoder, parser);

        convert.link_many (encoder, parser);

        var pad = convert.get_static_pad (CONVERT_SINK_PAD);
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = parser.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
