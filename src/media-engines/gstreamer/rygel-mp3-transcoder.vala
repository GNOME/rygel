/*
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Gee;

/**
 * Transcoder for mpeg 1 layer 3 audio.
 */
internal class Rygel.MP3Transcoder : Rygel.AudioTranscoder {
    public const int BITRATE = 128;
    private const string FORMAT = "audio/mpeg,mpegversion=1,layer=3";
    private const string NAME = "MP3";
    public MP3Transcoder () {
        base (NAME,
              "audio/mpeg",
              NAME,
              BITRATE,
              AudioTranscoder.NO_CONTAINER,
              FORMAT,
              "mp3");
    }
}
