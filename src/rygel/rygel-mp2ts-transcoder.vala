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
using GUPnP;

internal enum Rygel.MP2TSProfile {
    SD = 0,
    HD
}

internal class Rygel.MP2TSTranscoder : Rygel.Transcoder {
    // HD
    private const int[] WIDTH = {640, 1920};
    private const int[] HEIGHT = {480, 1080};
    private const string[] PROFILES = {"MPEG_TS_SD_NA", "MPEG_TS_HD_NA"};

    private MP2TSProfile profile;

    public MP2TSTranscoder (MP2TSProfile profile) {
        base ("video/mpeg", PROFILES[profile]);

        this.profile = profile;
    }

    public override Element create_source (Element src) throws Error {
        return new MP2TSTranscoderBin (src,
                                       MP2TSTranscoder.WIDTH[this.profile],
                                       MP2TSTranscoder.HEIGHT[this.profile]);
    }

    public override DIDLLiteResource create_resource (MediaItem        item,
                                                      TranscodeManager manager)
                                                      throws Error {
        var res = base.create_resource (item, manager);

        res.width = WIDTH[profile];
        res.height = HEIGHT[profile];

        return res;
    }
}
