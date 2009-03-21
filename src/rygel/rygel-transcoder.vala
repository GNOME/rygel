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

internal abstract class Rygel.Transcoder : Gst.Bin {
    // FIXME: This method must be replaced by Gst.Pad.is_compatible once
    //        it's there (i-e bug#575682 and 575685 are fixed).
    protected bool pads_compatible (Pad pad1, Pad pad2) {
        Caps intersection = pad1.get_caps ().intersect (pad2.get_caps ());

        return !intersection.is_empty ();
    }

    protected void post_error (Error error) {
        Message msg = new Message.error (this, error, error.message);
        this.post_message (msg);
    }
}
