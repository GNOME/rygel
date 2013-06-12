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

// Remove for GStreamer 1.0
[CCode (cname = "PRESET_DIR")]
internal extern static const string PRESET_DIR;

[CCode (cname="gst_preset_set_app_dir")]
extern bool gst_preset_set_app_dir (string app_dir);

public class Rygel.GstMediaEngine : Rygel.MediaEngine {
    private GLib.List<DLNAProfile> dlna_profiles = null;
    private GLib.List<Transcoder> transcoders = null;

    public GstMediaEngine () {
        unowned string[] args = null;

        Gst.init (ref args);
        gst_preset_set_app_dir (PRESET_DIR);

        /* Get the possible DLNA profiles
         * to add to the list of DLNA profiles supported by
         * this media engine, for get_dlna_profiles():
         */
        var discoverer = new GUPnPDLNA.ProfileGuesser (true, false);
        foreach (var profile in discoverer.list_profiles ()) {
            var p = new DLNAProfile (profile.name, profile.mime);

            /* TODO: Check that we (via GStreamer) really support this profile
             * instead of just claiming to support everything.
             */
            this.dlna_profiles.prepend (p);
        }
        this.dlna_profiles.prepend (new DLNAProfile ("DIDL_S", "text/xml"));

        this.dlna_profiles.reverse ();

        var transcoding = true;
        var transcoder_list = new ArrayList<string> ();

        /* Allow some transcoders to be disabled by the Rygel Server configuration.
         * For instance, some DLNA Renderers might incorrectly prefer inferior transcoded formats,
         * sometimes even preferring transcoded formats over the original data,
         * so this forces them to use other formats.
         */
        var config = MetaConfig.get_default ();
        try {
            transcoding = config.get_transcoding ();
            transcoder_list = config.get_string_list ("GstMediaEngine",
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
                        this.transcoders.prepend (new MP2TSTranscoder
                                        (MP2TSProfile.SD_EU));
                        this.transcoders.prepend (new MP2TSTranscoder
                                        (MP2TSProfile.SD_NA));
                        this.transcoders.prepend (new MP2TSTranscoder
                                        (MP2TSProfile.HD_NA));
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

    public override DataSource? create_data_source (string uri) {
        try {
            return new GstDataSource (uri);
        } catch (Error error) {
            warning (_("Failed to create GStreamer data source for %s: %s"),
                     uri,
                     error.message);

            return null;
        }
    }

    public DataSource create_data_source_from_element (Element element) {
        return new GstDataSource.from_element (element);
    }
}

public static Rygel.MediaEngine module_get_instance () {
    return new Rygel.GstMediaEngine ();
}
