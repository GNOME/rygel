/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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
using GUPnP;
using Gee;
using Gst;

/**
 * Represents Test video item.
 */
public class Rygel.TestVideoItem : Rygel.TestItem {
    const string TEST_MIMETYPE = "video/mpeg";

    public TestVideoItem (string         id,
                          MediaContainer parent,
                          string         title) {
        base (id,
              parent,
              title,
              TEST_MIMETYPE,
              MediaItem.VIDEO_CLASS);
    }

    public override Element? create_stream_source () {
        Bin bin = new Bin (this.title);

        dynamic Element src = ElementFactory.make ("videotestsrc", null);
        Element encoder = ElementFactory.make ("ffenc_mpeg2video", null);
        Element muxer = ElementFactory.make ("mpegtsmux", null);

        if (src == null || muxer == null || encoder == null) {
            warning ("Required plugin missing");

            return null;
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

