/*
 * Copyright (C) 2009 Nokia Corporation.
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

using GUPnP;
using Gee;

internal class Rygel.BrowseFilter : ArrayList<string> {
    public BrowseFilter (string filter_str) {
        base ((GLib.EqualFunc) BrowseFilter.filter_equal_func);

        var tokens = filter_str.split (",", -1);

        foreach (var token in tokens) {
            this.add (token);
        }
    }

    public bool have (string prop, string? prefix) {
        if (prefix != null) {
            return (prefix + ":" + prop) in this;
        } else {
            return (prop in this);
        }
    }

    public void adjust_resource (ref DIDLLiteResource res) {
        // Unset all optional props that are not requested
        if (!this.have ("res@importUri", null)) {
            res.import_uri = null;
        }

        if (!this.have ("res@protection", null)) {
            res.protection = null;
        }

        if (!this.have ("res@size", null)) {
            res.size = -1;
        }

        if (!this.have ("res@duration", null)) {
            res.duration = -1;
        }

        if (!this.have ("res@bitrate", null)) {
            res.bitrate = -1;
        }

        if (!this.have ("res@bitsPerSample", null)) {
            res.bits_per_sample = -1;
        }

        if (!this.have ("res@sampleFrequency", null)) {
            res.sample_freq = -1;
        }

        if (!this.have ("res@nrAudioChannels", null)) {
            res.n_audio_channels = -1;
        }

        if (!this.have ("res@colorDepth", null)) {
            res.color_depth = -1;
        }

        if (!this.have ("res@resolution", null)) {
            res.width = res.height = -1;
        }
    }

    private static bool filter_equal_func (string a, string b) {
        return a == "*" ||              // Wildcard
               a == b ||                // Exact match
               a == "@" + b ||          // top-level attribute, e.g @childCount
               a.has_prefix (b + "@");  // Attribute implies containing element
    }
}

