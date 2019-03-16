/*
 * Copyright (C) 2011 Nokia Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Prasanna Modem <prasanna@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gst;
using Gst.PbUtils;
using GUPnP;

/**
 * Base class for all transcoders that handle video.
 */
internal abstract class Rygel.VideoTranscoder : Rygel.AudioTranscoder {
    private int video_bitrate;
    private Caps video_codec_format;
    private Caps video_restrictions = null;

    protected VideoTranscoder (string  name,
                               string  content_type,
                               string  dlna_profile,
                               int     audio_bitrate,
                               int     video_bitrate,
                               string  container_caps,
                               string  audio_codec_caps,
                               string  video_codec_caps,
                               string  extension,
                               string? restrictions = null) {

        base.with_class (name,
                         content_type,
                         dlna_profile,
                         audio_bitrate,
                         container_caps,
                         audio_codec_caps,
                         extension);

        this.video_bitrate = video_bitrate;
        this.video_codec_format = Caps.from_string (video_codec_caps);

        if (restrictions != null) {
            this.video_restrictions = Caps.from_string (restrictions);
        }
    }

    public override uint get_distance (MediaFileItem item) {
        if (!(item is VideoItem)) {
            return uint.MAX;
        }

        var video_item = item as VideoItem;
        var distance = uint.MIN;

        if (video_item.bitrate > 0) {
            distance += (video_item.bitrate - this.video_bitrate).abs ();
        }

        return distance;
    }

    protected override EncodingProfile get_encoding_profile
                                        (MediaFileItem item) {
        var enc_container_profile = base.get_encoding_profile (item) as
                                        EncodingContainerProfile;

        var enc_video_profile = new EncodingVideoProfile
                                        (this.video_codec_format,
                                         this.preset,
                                         this.video_restrictions,
                                         1);
        enc_video_profile.set_name ("video");

        enc_container_profile.add_profile (enc_video_profile);

        return enc_container_profile;
    }

    public override MediaResource? get_resource_for_item (MediaFileItem item) {
        var resource = base.get_resource_for_item (item);
        if (resource == null) {
            return null;
        }

        var video_item = item as VideoItem;

        resource.width = video_item.width;
        resource.height = video_item.height;
        resource.bitrate = (this.video_bitrate + this.audio_bitrate) * 1000 / 8;

        return resource;
    }
}
