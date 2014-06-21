/*
 * Copyright (C) 2011 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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
using Gst.PbUtils;
using GUPnP;

/**
 * Base class for all transcoders that handle audio.
 */
internal class Rygel.AudioTranscoder : Rygel.GstTranscoder {
    protected int audio_bitrate;
    protected Caps container_format = null;
    protected Caps audio_codec_format = null;

    public const string NO_CONTAINER = null;

    public AudioTranscoder (string  content_type,
                            string  dlna_profile,
                            int     audio_bitrate,
                            string? container_caps,
                            string  audio_codec_caps,
                            string  extension) {
        base (content_type, dlna_profile, extension);

        this.audio_bitrate = audio_bitrate;
        if (container_caps != null) {
            this.container_format = Caps.from_string (container_caps);
        }

        this.audio_codec_format = Caps.from_string (audio_codec_caps);
    }

    public AudioTranscoder.with_class (string  content_type,
                                       string  dlna_profile,
                                       int     audio_bitrate,
                                       string? container_caps,
                                       string  audio_codec_caps,
                                       string  extension) {
        base (content_type, dlna_profile, extension);

        this.audio_bitrate = audio_bitrate;
        if (container_caps != null) {
            this.container_format = Caps.from_string (container_caps);
        }

        this.audio_codec_format = Caps.from_string (audio_codec_caps);
    }


    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaFileItem    item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null) {
            return null;
        }

        resource.bitrate = (this.audio_bitrate * 1000) / 8;

        return resource;
    }

    public override uint get_distance (MediaItem item) {
        if (!(item is AudioItem) || item is VideoItem) {
            return uint.MAX;
        }

        var audio_item = item as AudioItem;
        var distance = uint.MIN;

        if (audio_item.bitrate > 0) {
            distance += (audio_item.bitrate - this.audio_bitrate).abs ();
        }

        return distance;
    }

    protected override EncodingProfile get_encoding_profile () {
        var enc_audio_profile = new EncodingAudioProfile (audio_codec_format,
                                                          this.preset,
                                                          null,
                                                          1);
        enc_audio_profile.set_name ("audio");

        if (this.container_format != null) {
            var enc_container_profile = new EncodingContainerProfile ("container",
                                                                      null,
                                                                      container_format,
                                                                      this.preset);
            enc_container_profile.add_profile (enc_audio_profile);

            return enc_container_profile;
        }

        return enc_audio_profile;
    }
}
