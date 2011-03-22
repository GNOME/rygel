/*
 * Copyright (C) 2011 Nokia Corporation.
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

internal class Rygel.HTTPGstSink : BaseSink {
    public const string NAME = "http-gst-sink";
    public const string PAD_NAME = "sink";

    public signal void handoff (Buffer buffer, Pad pad);

    static construct {
        var caps = new Caps.any ();
        var template = new PadTemplate (PAD_NAME,
                                        PadDirection.SINK,
                                        PadPresence.ALWAYS,
                                        caps);
        add_pad_template (template);
    }

    public HTTPGstSink () {
        this.sync = false;
        this.name = NAME;
    }

    public override FlowReturn preroll (Buffer buffer) {
        return render (buffer);
    }

    public override FlowReturn render (Buffer buffer) {
        this.handoff (buffer, this.sinkpad);

        return FlowReturn.OK;
    }
}

