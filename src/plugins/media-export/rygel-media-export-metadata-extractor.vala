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
                                        GUPnP.DLNAInformation? info,
                                        string                 mime,
                                        uint64                 size,
                                        uint64                 mtime);

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

    public static MetadataExtractor? create () {
        return new MetadataExtractor ();
    }

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
            var gst_timeout = (ClockTime) (this.timeout * Gst.SECOND);
            this.discoverer = new GUPnP.DLNADiscoverer (gst_timeout);
            this.discoverer.done.connect (on_done);
            this.discoverer.start ();
        }
    }

    ~MetadataExtractor () {
        if (this.extract_metadata) {
            this.discoverer.stop ();
        }
    }

    private void on_done (GUPnP.DLNAInformation dlna,
                          GLib.Error        	err) {
        assert (this.file_hash.has_key (dlna.info.uri));

        File file = this.file_hash.get (dlna.info.uri);

        this.file_hash.unset (dlna.info.uri);

        if ((dlna.info.result & Gst.DiscovererResult.TIMEOUT) != 0) {
            this.error (file,
                        new IOChannelError.FAILED ("Pipeline stuck while" +
                                                   "reading file info"));
            return;
        } else if ((dlna.info.result & Gst.DiscovererResult.ERROR) != 0) {
            this.error (file, err);
            return;
        }

        try {
            uint64 size, mtime;
            string mime;

            this.extract_file_info (file, out mime, out size, out mtime);
            this.extraction_done (file, dlna, mime, size, mtime);
        } catch (Error e) {
            debug (_("Failed to extract metadata from %s: %s"),
                    dlna.info.uri,
                    e.message);
        }
    }

    public void extract (File file) {
        if (this.extract_metadata) {
            string uri = file.get_uri ();
            this.file_hash.set (uri, file);
            this.discoverer.discover_uri (uri);
        } else {
            try {
                string mime;
                uint64 size;
                uint64 mtime;

                extract_file_info (file,
                                   out mime,
                                   out size,
                                   out mtime);

                this.extraction_done (file,
                                      null,
                                      mime,
                                      size,
                                      mtime);
            } catch (Error error) {
                this.error (file, error);
            }
        }
    }

    private void extract_file_info (File       file,
                                    out string mime,
                                    out uint64 size,
                                    out uint64 mtime) throws Error {
        FileInfo file_info;

        try {
            file_info = file.query_info (FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE
                                         + "," +
                                         FILE_ATTRIBUTE_STANDARD_SIZE + "," +
                                         FILE_ATTRIBUTE_TIME_MODIFIED,
                                         FileQueryInfoFlags.NONE,
                                         null);
        } catch (Error error) {
            warning (_("Failed to query content type for '%s'"),
                     file.get_uri ());

            // signal error to parent
            this.error (file, error);

            throw error;
        }

        string content_type = file_info.get_content_type ();
        mime = g_content_type_get_mime_type (content_type);
        size = file_info.get_size ();
        mtime = file_info.get_attribute_uint64 (FILE_ATTRIBUTE_TIME_MODIFIED);
    }
}
