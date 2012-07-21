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
using Gee;
using GUPnP;

/**
 * Metadata extractor based on Gstreamer. Just set the URI of the media on the
 * uri property, it will extact the metadata for you and emit signal
 * metadata_available for each key/value pair extracted.
 */
public class Rygel.MediaExport.MetadataExtractor: GLib.Object {
    /* Signals */
    public signal void extraction_done (File                   file,
                                        GUPnP.DLNAInformation? dlna,
                                        FileInfo               file_info);

    /**
     * Signalize that an error occured during metadata extraction
     */
    public signal void error (File file, Error err);

    private GUPnP.DLNADiscoverer discoverer;
    /**
     * We export a GLib.File-based API but GstDiscoverer works with URIs, so
     * we store uri->GLib.File mappings in this hashmap, so that we can get
     * the GLib.File back from the URI in on_discovered().
     */
    private HashMap<string, File> file_hash;
    private uint64 timeout = 10; /* seconds */

    private bool extract_metadata;

    public MetadataExtractor () {
        this.file_hash = new HashMap<string, File> ();

        var config = MetaConfig.get_default ();
        try {
            this.extract_metadata = config.get_bool ("MediaExport",
                                                     "extract-metadata");
        } catch (Error error) {
            this.extract_metadata = true;
        }


        if (this.extract_metadata) {

        }
    }

    public void extract (File file) {
        if (this.extract_metadata) {
            string uri = file.get_uri ();
            this.file_hash.set (uri, file);
            var gst_timeout = (ClockTime) (this.timeout * Gst.SECOND);
            this.discoverer = new GUPnP.DLNADiscoverer (gst_timeout,
                                                        true,
                                                        true);
            this.discoverer.done.connect (on_done);
            this.discoverer.start ();
            this.discoverer.discover_uri (uri);
        } else {
            this.extract_basic_information (file);
        }
    }

    private void on_done (GUPnP.DLNAInformation dlna,
                          GLib.Error            err) {
        this.discoverer.done.disconnect (on_done);
        this.discoverer = null;
        var file = this.file_hash.get (dlna.info.get_uri ());
        if (file == null) {
            warning ("File %s already handled, ignoring event",
                     dlna.info.get_uri ());

            return;
        }

        this.file_hash.unset (dlna.info.get_uri ());

        if ((dlna.info.get_result () & Gst.DiscovererResult.TIMEOUT) != 0) {
            debug ("Extraction timed out on %s", file.get_uri ());

            // set dlna to null to extract basic file information
            dlna = null;
        } else if ((dlna.info.get_result () &
                    Gst.DiscovererResult.ERROR) != 0) {
            this.error (file, err);

            return;
        }

        this.extract_basic_information (file, dlna);
    }

    private void extract_basic_information (File file,
                                            DLNAInformation? dlna = null) {
        try {
            FileInfo file_info;

            try {
                file_info = file.query_info
                                        (FileAttribute.STANDARD_CONTENT_TYPE
                                         + "," +
                                         FileAttribute.STANDARD_SIZE + "," +
                                         FileAttribute.TIME_MODIFIED + "," +
                                         FileAttribute.STANDARD_DISPLAY_NAME,
                                         FileQueryInfoFlags.NONE,
                                         null);
            } catch (Error error) {
                warning (_("Failed to query content type for '%s'"),
                        file.get_uri ());

                // signal error to parent
                this.error (file, error);

                throw error;
            }

            this.extraction_done (file,
                                  dlna,
                                  file_info);
        } catch (Error error) {
            debug ("Failed to extract basic metadata from %s: %s",
                   file.get_uri (),
                   error.message);
            this.error (file, error);
        }

    }

}
