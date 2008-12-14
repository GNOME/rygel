/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Rygel;
using GUPnP;
using Gee;
using Gst;

/**
 * Represents Test video item.
 */
public class Rygel.TestVideoItem : Rygel.TestItem {
    const string TEST_PATH = "/test.avi";
    const string TEST_MIMETYPE = "video/x-msvideo";

    public TestVideoItem (string   id,
                          string   parent_id,
                          string   title,
                          Streamer streamer) {
        base (id,
              parent_id,
              title,
              TEST_MIMETYPE,
              MediaItem.VIDEO_CLASS,
              streamer,
              TEST_PATH);
    }

    protected override Element create_gst_source () throws Error {
        Bin bin = new Bin (this.title);

        dynamic Element src = ElementFactory.make ("videotestsrc", null);
        Element encoder = ElementFactory.make ("ffenc_h263", null);
        Element muxer = ElementFactory.make ("avimux", null);

        if (src == null || muxer == null || encoder == null) {
            throw new GstStreamError.MISSING_PLUGIN ("Required plugin missing");
        }

        // Tell the source to behave like a live source
        src.is_live = true;

        // Add elements to our source bin
        bin.add_many (src, encoder, muxer);
        // Link them
        src.link_many (encoder, muxer);

        // Now add the encoder's src pad to the bin
        Pad pad = muxer.get_static_pad ("src");
        var ghost = new GhostPad (bin.name + "." + pad.name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}

