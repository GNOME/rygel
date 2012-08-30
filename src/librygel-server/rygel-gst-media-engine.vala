/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

internal class Rygel.GstMediaEngine : Rygel.MediaEngine {
    private GLib.List<DLNAProfile> dlna_profiles = null;

    public GstMediaEngine () {
        var discoverer = new GUPnP.DLNADiscoverer ((ClockTime) SECOND,
                                                   true,
                                                   false);
        foreach (var profile in discoverer.list_profiles ()) {
            var p = new DLNAProfile (profile.mime, profile.name);
            this.dlna_profiles.prepend (p);
        }

        this.dlna_profiles.reverse ();
    }

    public override unowned GLib.List<DLNAProfile> get_dlna_profiles () {
        return this.dlna_profiles;
    }
}
