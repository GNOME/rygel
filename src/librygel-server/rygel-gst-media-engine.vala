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
        var lpcm_transcoder = true;
        var mp3_transcoder = true;
        var mp2ts_transcoder = true;
        var wmv_transcoder = true;
        var aac_transcoder = true;
        var avc_transcoder = true;

        var config = MetaConfig.get_default ();
        try {
            transcoding = config.get_transcoding ();

            if (transcoding) {
                lpcm_transcoder = config.get_lpcm_transcoder ();
                mp3_transcoder = config.get_mp3_transcoder ();
                mp2ts_transcoder = config.get_mp2ts_transcoder ();
                wmv_transcoder = config.get_wmv_transcoder ();
                aac_transcoder = config.get_aac_transcoder ();
                avc_transcoder = config.get_avc_transcoder ();
            }
        } catch (Error err) {}

        if (transcoding) {
            if (lpcm_transcoder) {
                this.transcoders.prepend (new L16Transcoder ());
            }

            if (mp3_transcoder) {
                this.transcoders.prepend (new MP3Transcoder ());
            }

            if (mp2ts_transcoder) {
                this.transcoders.prepend (new MP2TSTranscoder(MP2TSProfile.SD));
                this.transcoders.prepend (new MP2TSTranscoder(MP2TSProfile.HD));
            }

            if (wmv_transcoder) {
                this.transcoders.prepend (new WMVTranscoder ());
            }

            if (aac_transcoder) {
                this.transcoders.prepend (new AACTranscoder ());
            }

            if (avc_transcoder) {
                this.transcoders.prepend (new AVCTranscoder ());
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
}
