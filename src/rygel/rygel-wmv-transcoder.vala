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

internal class Rygel.WMVTranscoder : Rygel.Transcoder {
    private const int VIDEO_BITRATE = 1200;
    private const int BITRATE = 1200000;

    private const string VIDEO_ENCODER = "ffenc_wmv1";
    private const string COLORSPACE_CONVERT = "ffmpegcolorspace";
    private const string VIDEO_RATE = "videorate";
    private const string VIDEO_SCALE = "videoscale";

    public WMVTranscoder () {
        base ("video/x-ms-wmv", "WMVHIGH_FULL", VideoItem.UPNP_CLASS);
    }

    public override Element create_source (MediaItem item,
                                           Element   src)
                                           throws Error {
        return new WMVTranscoderBin (item, src, this);
    }

    public override DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                    MediaItem        item,
                                                    TranscodeManager manager)
                                                    throws Error {
        var resource = base.add_resource (didl_item, item, manager);
        if (resource == null)
            return null;

        var video_item = item as VideoItem;

        resource.width = video_item.width;
        resource.height = video_item.height;
        resource.bitrate = (VIDEO_BITRATE + WMATranscoder.BITRATE) * 1000 / 8;

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

        return distance;
    }

    public Element create_encoder (MediaItem item,
                                   string?   src_pad_name,
                                   string?   sink_pad_name)
                                   throws Error {
        var convert = GstUtils.create_element (COLORSPACE_CONVERT,
                                               COLORSPACE_CONVERT);
        dynamic Element encoder = GstUtils.create_element (VIDEO_ENCODER,
                                                           VIDEO_ENCODER);

        encoder.bitrate = (int) VIDEO_BITRATE * 1000;

        var bin = new Bin ("video-encoder-bin");
        bin.add_many (convert, encoder);
        convert.link (encoder);

        var pad = convert.get_static_pad ("sink");
        var ghost = new GhostPad (sink_pad_name, pad);
        bin.add_pad (ghost);

        pad = encoder.get_static_pad ("src");
        ghost = new GhostPad (src_pad_name, pad);
        bin.add_pad (ghost);

        return bin;
    }

}
