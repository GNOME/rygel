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
using Gee;

internal class Rygel.GstMediaEngine : Rygel.MediaEngine {
    private GLib.List<DLNAProfile> dlna_profiles = null;
    private GLib.List<Transcoder> transcoders = null;

    public GstMediaEngine () {
        var discoverer = new GUPnP.DLNADiscoverer ((ClockTime) SECOND,
                                                   true,
                                                   false);
        foreach (var profile in discoverer.list_profiles ()) {
            var p = new DLNAProfile (profile.mime, profile.name);
            this.dlna_profiles.prepend (p);
        }

        this.dlna_profiles.reverse ();

        var transcoding = true;
        var transcoder_list = new ArrayList<string> ();

        var config = MetaConfig.get_default ();
        try {
            transcoding = config.get_transcoding ();
            transcoder_list = config.get_string_list ("MediaEngine",
                                                      "transcoders");
        } catch (Error err) {}

        if (transcoding) {
            foreach (var transcoder in transcoder_list) {
                switch (transcoder) {
                    case "lpcm":
                        this.transcoders.prepend (new L16Transcoder ());
                        break;
                    case "mp3":
                        this.transcoders.prepend (new MP3Transcoder ());
                        break;
                    case "mp2ts":
                        this.transcoders.prepend (new MP2TSTranscoder(MP2TSProfile.SD));
                        this.transcoders.prepend (new MP2TSTranscoder(MP2TSProfile.HD));
                        break;
                    case "wmv":
                        this.transcoders.prepend (new WMVTranscoder ());
                        break;
                    case "aac":
                        this.transcoders.prepend (new AACTranscoder ());
                        break;
                    case "avc":
                        this.transcoders.prepend (new AVCTranscoder ());
                        break;
                    default:
                        debug ("Unsupported transcoder \"%s\"", transcoder);
                        break;
                }
            }

            this.transcoders.reverse ();
        }
    }

    public override unowned GLib.List<DLNAProfile> get_dlna_profiles () {
        return this.dlna_profiles;
    }

    public override unowned GLib.List<Transcoder>? get_transcoders () {
        return this.transcoders;
    }

    public override DataSource create_data_source (string uri) {
        return new GstDataSource (uri);
    }
}
