/*
 * Copyright (C) 2015 Jens Georg <mail@jensge.org>
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

using GUPnP;

internal class Rygel.MediaExport.DVDTrack : Rygel.VideoItem {
    public DVDTrack (string         id,
                     MediaContainer parent,
                     string         title) {
        base (id, parent, title, Rygel.VideoItem.UPNP_CLASS);
    }

    public override MediaResource get_primary_resource () {
        var res = base.get_primary_resource ();

        // We don't have proper access to tbe bytes, but time seek should week
        res.dlna_operation = DLNAOperation.TIMESEEK;

        return res;
    }
}
