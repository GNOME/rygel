/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Prasanna Modem <prasanna@ecaspia.com>
 *         Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gst;
using Gee;
using GUPnP;

public class Rygel.GstMediaEngine : Rygel.MediaEngine {
    private GLib.List<DLNAProfile> dlna_profiles = null;
    private GLib.List<GstTranscoder> transcoders = null;

    public GstMediaEngine () {
        unowned string[] args = null;

        Gst.init (ref args);
        GES.init ();
        Gst.Preset.set_app_dir (BuildConfig.PRESET_DIR);

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

        /* Allow some transcoders to be disabled by the Rygel Server
         * configuration.  For instance, some DLNA Renderers might incorrectly
         * prefer inferior transcoded formats, sometimes even preferring
         * transcoded formats over the original data, so this forces them to
         * use other formats.
         */
        var config = MetaConfig.get_default ();
        try {
            transcoding = config.get_transcoding ();
            transcoder_list = config.get_string_list ("GstMediaEngine",
                                                      "transcoders");
        } catch (Error err) {}

        if (transcoding) {
            this.transcoders.prepend (new JPEGTranscoder ());
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

    public override async Gee.List<MediaResource>? get_resources_for_item
                                        (MediaObject object) {
        if (!(object is MediaFileItem)) {
            warning ("Can only process file-based MediaObjects (MediaFileItems)");

            return null;
        }

        var item = object as MediaFileItem;

        // For MediaFileItems, the primary URI refers directly to the content
        var source_uri = item.get_primary_uri ();
        var scheme = GLib.Uri.parse_scheme (source_uri);
        var uri_is_http = scheme.has_prefix ("http");

        if (scheme == null) {
            warning (_("Invalid URI without prefix: %s"), source_uri);

            return null;
        }


        debug ("get_resources_for_item(%s), protocol: %s", source_uri, scheme);

        if (!Gst.Uri.protocol_is_supported (URIType.SRC, scheme) &&
            scheme != "gst-launch" &&
            scheme != "dvd") {
            warning (_("Can’t process URI %s with protocol %s"),
                     source_uri,
                     scheme);

            return null;
        }

        var resources = new Gee.ArrayList<MediaResource> ();
        var primary_res = item.get_primary_resource ();

        // The GstMediaEngine only supports byte-based seek on the primary
        // resource currently

        // The GstMediaEngine supports connection stalling on the primary
        // resource
        primary_res.dlna_flags |= DLNAFlags.CONNECTION_STALL;

        if (!uri_is_http) {
            // Add a resource for http consumption
            var http_res = new MediaResource.from_resource ("primary_http",
                                                            primary_res);
            http_res.uri = ""; // The URI needs to be assigned by the MediaServer
            resources.add (http_res);
        }

        if (!item.place_holder) {
            var list = new GLib.List<GstTranscoder> ();
            foreach (var transcoder in transcoders) {
                if (transcoder.get_distance (item) != uint.MAX &&
                    transcoder.transcoding_necessary (item)) {
                    list.append (transcoder);
                }
            }

            list.sort_with_data( (transcoder_1, transcoder_2) => {
                return (int) (transcoder_1.get_distance (item) -
                              transcoder_2.get_distance (item));
            });

            // Put all Transcoders in the list according to their sorted rank
            foreach (var transcoder in list) {
                var res = transcoder.get_resource_for_item (item);
                if (res != null) {
                    resources.add (res);
                }
            }
        }

        // Put the primary resource as most-preferred (front of the list)
        if (primary_res.uri != null && uri_is_http) {
            resources.insert (0, primary_res);
        } else {
            resources.add (primary_res);
        }

        return resources;
    }

    public override DataSource? create_data_source_for_resource
                                        (MediaObject   object,
                                         MediaResource resource,
                                         HashTable<string, string> replacements)
                                        throws Error {
        if (!(object is MediaFileItem)) {
            warning ("Can only process file-based MediaObjects (MediaFileItems)");

            return null;
        }
        var item = object as MediaFileItem;

        // For MediaFileItems, the primary URI refers directly to the content
        var source_uri = item.get_primary_uri ();
        debug ("creating data source for %s", source_uri);
        source_uri = MediaObject.apply_replacements (replacements, source_uri);
        debug ("source_uri after applying replacements: %s", source_uri);

        var data_source = new GstDataSource (source_uri, resource);
        debug ("MediaResource %s, profile %s, mime_type %s",
               resource.get_name (),
               resource.dlna_profile,
               resource.mime_type);

        if (resource.dlna_conversion == DLNAConversion.TRANSCODED) {
            foreach (var transcoder in transcoders) {
                if (transcoder.name == resource.get_name ()) {
                    debug ("Creating data source from transcoder %s " +
                           "with DLNA profile %s",
                            transcoder.name,
                            transcoder.dlna_profile);
                    data_source = transcoder.create_source (item, data_source);

                    break;
                }
            }
        }

        return data_source;
    }

    public override DataSource? create_data_source_for_uri (string source_uri) {
        try {
            debug("creating data source for %s", source_uri);

            return new GstDataSource (source_uri, null);
        } catch (Error error) {
            warning (_("Failed to create GStreamer data source for %s: %s"),
                     source_uri,
                     error.message);

            return null;
        }
    }

    public DataSource create_data_source_from_element (Element element) {
        return new GstDataSource.from_element (element);
    }

    public override GLib.List<string> get_internal_protocol_schemes () {
        var list = new GLib.List<string> ();
        list.prepend ("dvd");
        list.prepend ("gst-launch");

        return list;
    }
}

public static Rygel.MediaEngine module_get_instance () {
    return new Rygel.GstMediaEngine ();
}
