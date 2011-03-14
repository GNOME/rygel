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

internal enum Rygel.MP2TSProfile {
    SD = 0,
    HD
}

/**
 * Transcoder for mpeg transport stream containing mpeg 2 video and mp2 audio.
 */
internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    private const int VIDEO_BITRATE = 3000;
    private const int AUDIO_BITRATE = 256;

    // HD
    private const int[] WIDTH = {720, 1280};
    private const int[] HEIGHT = {576, 720};
    private const int[] FRAME_RATE = {25, 30};
    private const string[] PROFILES = {"MPEG_TS_SD_EU_ISO", "MPEG_TS_HD_NA_ISO"};
    private const int BITRATE = 3000000;

    private const string DECODE_BIN = "decodebin2";
    private const string ENCODE_BIN = "encodebin";

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg", PROFILES[profile], VideoItem.UPNP_CLASS);

        this.profile = profile;
    }

    public override Element create_source (MediaItem item,
                                           Element   src)
                                           throws Error {
        dynamic Element decoder = GstUtils.create_element (DECODE_BIN,
                                                           DECODE_BIN);
        dynamic Element encoder = GstUtils.create_element (ENCODE_BIN,
                                                           ENCODE_BIN);

        encoder.profile = this.get_encoding_profile ();

        var bin = new Bin ("mp2-ts-transcoder-bin");
        bin.add_many (src, decoder, encoder);

        src.link (decoder);

        decoder.pad_added.connect (this.on_decoder_pad_added);

        var pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (null, pad);
        bin.add_pad (ghost);

        return bin;
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null)
            return null;

        resource.width = WIDTH[profile];
        resource.height = HEIGHT[profile];
        resource.bitrate = (VIDEO_BITRATE + AUDIO_BITRATE) * 1000 / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is VideoItem)) {
            return uint.MAX;
        }

        var video_item = item as VideoItem;
        var distance = uint.MIN;

        if (video_item.bitrate > 0) {
            distance += (video_item.bitrate - BITRATE).abs ();
        }

        if (video_item.width > 0) {
            distance += (video_item.width - WIDTH[this.profile]).abs ();
        }

        if (video_item.height > 0) {
            distance += (video_item.height - HEIGHT[this.profile]).abs ();
        }

        return distance;
    }

    private void on_decoder_pad_added (Element decodebin, Pad new_pad) {
        var bin = decodebin.get_parent () as Bin;
        assert (bin != null);

        var encoder = bin.get_by_name (ENCODE_BIN);
        assert (encoder != null);

        var encoder_pad = encoder.get_compatible_pad (new_pad, null);
        if (encoder_pad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring..",
                   new_pad.name);
            return;
        } else {
            debug ("pad '%s' with caps '%s' is compatible with '%s'",
                   new_pad.name,
                   new_pad.get_caps ().to_string (),
                   encoder_pad.name);
        }

        if (new_pad.link (encoder_pad) != PadLinkReturn.OK) {
            var error = new GstError.LINK (_("Failed to link pad %s to %s"),
                                           new_pad.name,
                                           encoder_pad.name);
            GstUtils.post_error (bin, error);
        }
    }

    private EncodingContainerProfile get_encoding_profile () {
        var container_format = Caps.from_string ("video/mpegts," +
                                                 "systemstream=true," +
                                                 "packetsize=188");

        var enc_container_profile = new EncodingContainerProfile
                                        ("mpeg-ts-profile",
                                         null,
                                         container_format,
                                         null);

        enc_container_profile.add_profile (this.get_video_profile ());
        enc_container_profile.add_profile (this.get_audio_profile ());

        return enc_container_profile;
    }

    private EncodingVideoProfile get_video_profile () {
        var format = Caps.from_string ("video/mpeg," +
                                       "mpegversion=2," +
                                       "systemstream=false," +
                                       "framerate=(fraction)25/1");
        var restriction = Caps.from_string
                                        ("video/x-raw-yuv,width=" +
                                         WIDTH[this.profile].to_string () +
                                         ",height=" +
                                         HEIGHT[this.profile].to_string () +
                                         ",framerate=(fraction)" +
                                         FRAME_RATE[this.profile].to_string () +
                                         "/1");

        // FIXME: We should use the preset to set bitrate
        return new EncodingVideoProfile (format, null, restriction, 1);
    }

    private EncodingAudioProfile get_audio_profile () {
        var format = Caps.from_string ("audio/mpeg,mpegversion=4");

        // FIXME: We should use the preset to set bitrate
        return new EncodingAudioProfile (format, null, null, 1);
    }
}
