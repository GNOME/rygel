/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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


using Gst;
using Gst.PbUtils;
using Gee;
using GUPnP;
using GUPnPDLNA;

/**
 * Metadata extractor based on Gstreamer. Just set the URI of the media on the
 * uri property, it will extact the metadata for you and emit signal
 * metadata_available for each key/value pair extracted.
 */
public class Rygel.MediaExport.MetadataExtractor: GLib.Object {
    /* Signals */
    public signal void extraction_done (File               file,
                                        DiscovererInfo?    info,
                                        GUPnPDLNA.Profile? profile,
                                        FileInfo           file_info);

    /**
     * Signalize that an error occured during metadata extraction
     */
    public signal void error (File file, Error err);

    private Discoverer discoverer;
    private ProfileGuesser guesser;

    /**
     * We export a GLib.File-based API but GstDiscoverer works with URIs, so
     * we store uri->GLib.File mappings in this hashmap, so that we can get
     * the GLib.File back from the URI in on_discovered().
     */
    private HashMap<string, File> file_hash;
    private uint timeout = 10; /* seconds */

    private bool extract_metadata;

    public MetadataExtractor () {
        this.file_hash = new HashMap<string, File> ();

        var config = MetaConfig.get_default ();
        config.setting_changed.connect (this.on_config_changed);
        this.on_config_changed (config, Plugin.NAME, "extract-metadata");
    }

    public void extract (File file, string content_type) {
        if (this.extract_metadata && !content_type.has_prefix ("text/")) {
            string uri = file.get_uri ();
            try {
                var gst_timeout = (ClockTime) (this.timeout * Gst.SECOND);

                this.discoverer = new Discoverer (gst_timeout);
            } catch (Error error) {
                debug ("Failed to create a discoverer. Doing basic extraction.");
                this.extract_basic_information (file, null, null);

                return;
            }
            this.file_hash.set (uri, file);
            this.discoverer.discovered.connect (on_done);
            this.discoverer.start ();
            this.discoverer.discover_uri_async (uri);
            this.guesser = new GUPnPDLNA.ProfileGuesser (true, true);
        } else {
            this.extract_basic_information (file, null, null);
        }
    }

    private void on_done (DiscovererInfo info, GLib.Error err) {
        this.discoverer = null;
        var file = this.file_hash.get (info.get_uri ());
        if (file == null) {
            warning ("File %s already handled, ignoring event",
                     info.get_uri ());

            return;
        }

        this.file_hash.unset (info.get_uri ());

        if ((info.get_result () & DiscovererResult.TIMEOUT) != 0) {
            debug ("Extraction timed out on %s", file.get_uri ());
            this.extract_basic_information (file, null, null);

            return;
        } else if ((info.get_result () &
                    DiscovererResult.ERROR) != 0) {
            this.error (file, err);

            return;
        }

        var dlna_info = GUPnPDLNAGst.utils_information_from_discoverer_info (info);
        var dlna = this.guesser.guess_profile_from_info (dlna_info);
        this.extract_basic_information (file, info, dlna);
    }

    private void extract_basic_information (File               file,
                                            DiscovererInfo?    info,
                                            GUPnPDLNA.Profile? dlna) {
        FileInfo file_info;

        try {
            file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE
                                         + "," +
                                         FileAttribute.STANDARD_SIZE + "," +
                                         FileAttribute.TIME_MODIFIED + "," +
                                         FileAttribute.STANDARD_DISPLAY_NAME,
                                         FileQueryInfoFlags.NONE,
                                         null);
        } catch (Error error) {
            var uri = file.get_uri ();

            warning (_("Failed to query content type for '%s'"),
                     uri);
            debug ("Failed to extract basic metadata from %s: %s",
                   uri,
                   error.message);

            // signal error to parent
            this.error (file, error);
            return;
        }

        this.extraction_done (file,
                              info,
                              dlna,
                              file_info);
    }

    private void on_config_changed (Configuration config,
                                    string section,
                                    string key) {
        if (section != Plugin.NAME || key != "extract-metadata") {
            return;
        }

        try {
            this.extract_metadata = config.get_bool (Plugin.NAME,
                                                     "extract-metadata");
        } catch (Error error) {
            this.extract_metadata = true;
        }
    }
}
