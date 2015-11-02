/*
 * Copyright (C) 2011 Nokia Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Luis de Bethencourt <luis.debethencourt@collabora.com>
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
using GUPnP;

/**
 * Transcoder for H.264 in MP4 conforming to DLNA profile
 * AVC_MP4_BL_CIF15_AAC_520 (15 fps, CIF resolution)
 */
internal class Rygel.AVCTranscoder : Rygel.VideoTranscoder {
    private const int VIDEO_BITRATE = 1200;
    private const int AUDIO_BITRATE = 64;
    private const string CONTAINER = "video/quicktime,variant=iso";
    private const string AUDIO_CAPS = "audio/mpeg,mpegversion=4";
    private const string VIDEO_CAPS =
        "video/x-h264,stream-format=avc";

    private const string RESTRICTIONS =
        "video/x-raw,framerate=(fraction)15/1,width=352,height=288";

    private const string NAME = "AVC_MP4_BL_CIF15_AAC_520";
    public AVCTranscoder () {
        base (NAME,
              "video/mp4",
              NAME,
              AUDIO_BITRATE,
              VIDEO_BITRATE,
              CONTAINER,
              AUDIO_CAPS,
              VIDEO_CAPS,
              "mp4",
              RESTRICTIONS);
        this.preset = "Rygel AVC_MP4_BL_CIF15_AAC_520 preset";
    }
}
