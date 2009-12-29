/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.WMATranscoder : Rygel.Transcoder {
    private const int BITRATE = 64;

    private const string CONVERT_SINK_PAD = "convert-sink-pad";

    public WMATranscoder () {
        base ("audio/x-wma", "WMA", MediaItem.AUDIO_CLASS);
    }

    public override Element create_source (MediaItem item,
                                           Element   src)
                                           throws Error {
        return new WMATranscoderBin (item, src, this);
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
        if (item.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            return uint.MAX;
        }

        uint distance;

        if (item.upnp_class.has_prefix (MediaItem.AUDIO_CLASS)) {
            distance = uint.MIN;

            if (item.bitrate > 0) {
                distance += (item.bitrate - BITRATE).abs ();
            }
        } else {
            distance = uint.MAX / 2;
        }

        return distance;
    }

    public Element create_encoder (MediaItem item,
                                   string?   src_pad_name,
                                   string?   sink_pad_name)
                                   throws Error {
        var l16_transcoder = new L16Transcoder (Endianness.LITTLE);
        dynamic Element convert = l16_transcoder.create_encoder (
                                       item,
                                       null,
                                       CONVERT_SINK_PAD);

        dynamic Element encoder = GstUtils.create_element ("ffenc_wmav2",
                                                           "ffenc_wmav2");
        encoder.bitrate = BITRATE * 1000;

        var bin = new Bin("wma-encoder-bin");
        bin.add_many (convert, encoder);
        convert.link (encoder);

        var pad = convert.get_static_pad (CONVERT_SINK_PAD);
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = encoder.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}
