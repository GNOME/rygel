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

/**
 * Metadata extractor based on Gstreamer. Just set the URI of the media on the
 * uri property, it will extact the metadata for you and emit signal
 * metadata_available for each key/value pair extracted.
 */
public class Rygel.MediaExport.MetadataExtractor: GLib.Object {
    public const string TAG_RYGEL_SIZE = "rygel-size";
    public const string TAG_RYGEL_MIME = "rygel-mime";
    public const string TAG_RYGEL_CHANNELS = "rygel-channels";
    public const string TAG_RYGEL_RATE = "rygel-rate";
    public const string TAG_RYGEL_WIDTH = "rygel-width";
    public const string TAG_RYGEL_HEIGHT = "rygel-height";
    public const string TAG_RYGEL_DEPTH = "rygel-depth";
    public const string TAG_RYGEL_MTIME = "rygel-mtime";

    private const Quark _STREAM_TOPOLOGY_QUARK =
                                        Quark.from_string ("stream-topology");

    /* Signals */
    public signal void extraction_done (File file, Gst.TagList tag_list);

    /**
     * Signalize that an error occured during metadata extraction
     */
    public signal void error (File file, Error err);

    private Gst.Discoverer discoverer;
    /**
     * We export a File-based API but GstDiscoverer works with URIs, so
     * we store uri->File mappings in this hashmap
     */
    private HashMap<string, File> file_hash;
    private uint64 timeout = 10; /* seconds */

    private static void register_custom_tag (string tag, Type type) {
        Gst.tag_register (tag,
                          TagFlag.META,
                          type,
                          tag,
                          "",
                          Gst.tag_merge_use_first);
    }

    public static MetadataExtractor? create () {
        return new MetadataExtractor ();
    }

    public MetadataExtractor () {
        this.register_custom_tag (TAG_RYGEL_SIZE, typeof (int64));
        this.register_custom_tag (TAG_RYGEL_MIME, typeof (string));
        this.register_custom_tag (TAG_RYGEL_CHANNELS, typeof (int));
        this.register_custom_tag (TAG_RYGEL_RATE, typeof (int));
        this.register_custom_tag (TAG_RYGEL_WIDTH, typeof (int));
        this.register_custom_tag (TAG_RYGEL_HEIGHT, typeof (int));
        this.register_custom_tag (TAG_RYGEL_DEPTH, typeof (int));
        this.register_custom_tag (TAG_RYGEL_MTIME, typeof (uint64));

        this.file_hash = new HashMap<string, File> ();

        this.discoverer = new Gst.Discoverer ((ClockTime)
                                              (this.timeout * 1000000000ULL));
        this.discoverer.discovered.connect (on_discovered);
        this.discoverer.start ();
    }

    ~MetadataExtractor () {
        this.discoverer.stop ();
    }

    private void on_discovered (string               uri,
                                Structure            info,
                                GLib.Error           err,
                                Gst.DiscovererResult res) {
        assert (this.file_hash.has_key (uri));

        File file = this.file_hash.get (uri);
        TagList tag_list = new TagList ();

        this.file_hash.unset (uri);

        if ((res & Gst.DiscovererResult.TIMEOUT) != 0) {
            this.error (file,
                        new IOChannelError.FAILED ("Pipeline stuckwhile" +
                                                   "reading file info"));
            return;
        } else if ((res & Gst.DiscovererResult.ERROR) != 0) {
            this.error (file, err);
            return;
        }

        try {
            this.extract_mime_and_size (file, tag_list);
            this.extract_duration (info, tag_list);
            this.extract_stream_info (info, tag_list);
            this.extraction_done (file, tag_list);
        } catch (Error e) {
            /* Passthrough */
        }
    }

    public void extract (File file) {
        string uri = file.get_uri ();
        this.file_hash.set (uri, file);
        this.discoverer.append_uri (uri);
    }

    private void extract_mime_and_size (File    file,
                                        TagList tag_list) throws Error {
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
        string mime = g_content_type_get_mime_type (content_type);

        if (mime != null) {
            /* add custom mime tag to tag list */
            tag_list.add (TagMergeMode.REPLACE, TAG_RYGEL_MIME, mime);
        }

        var size = file_info.get_size ();
        tag_list.add (TagMergeMode.REPLACE, TAG_RYGEL_SIZE, size);

        var mtime = file_info.get_attribute_uint64 (
                                        FILE_ATTRIBUTE_TIME_MODIFIED);
        tag_list.add (TagMergeMode.REPLACE, TAG_RYGEL_MTIME, mtime);
    }

    private void extract_duration (Structure info, TagList tag_list) {
        ClockTime duration;
        this.discoverer.results_get_duration (info, out duration);

        tag_list.add (TagMergeMode.REPLACE,
                      TAG_DURATION,
                      info.duration);
    }

    /*
     * Collect Caps from the stream information so we can extract bitrate,
     * height, width, etc.
     */
    private ArrayList<Gst.Caps> get_caps (Structure info) {
        ArrayList<Gst.Caps> caps_list = new ArrayList<Gst.Caps> ();
        ArrayList<Structure> struct_list = new ArrayList<Structure> ();

        struct_list.add (info);

        for (int i = 0; i < struct_list.size; i++) {
            Structure st = struct_list[i];

            for (int f = 0; f < st.n_fields (); f++) {
                string name = st.nth_field_name (f);
                Quark field = Quark.from_string (name);
                Gst.Value v = st.get_value (name);

                if (field == MetadataExtractor._STREAM_TOPOLOGY_QUARK) {
                    /* We don't care about the stream topology caps */
                    continue;
                } else if (v.holds (typeof (Gst.List))) {
                    for (int j = 0; j < v.list_get_size (); j++) {
                        Gst.Value item_value = v.list_get_value (j);

                        if (item_value.type ().name () == "GstStructure")
                            struct_list.add (item_value.get_structure ());
                        else if (item_value.holds (typeof (Gst.Caps)))
                            caps_list.add (item_value.get_caps ());
                    }
                } else if (v.type ().name () == "GstStructure") {
                    /*
                     * This should be v.holds (typeof (Gst.Structure)), but
                     * requires a bug fix in GStreamer VAPI, which should hit
                     * master soon
                     */
                    struct_list.add (v.get_structure ());
                } else if (v.holds (typeof (Gst.Caps))) {
                    caps_list.add (v.get_caps ());
                }
            }
        }

        return caps_list;
    }

    private void extract_stream_info (Structure info, TagList tag_list) {
        ArrayList<Gst.Caps> caps_list = get_caps (info);

        foreach (Gst.Caps caps in caps_list) {
            Structure caps_struct = caps.get_structure (0);
            string name = caps_struct.get_name ();

            if (name.has_prefix ("video")) {
                extract_video_info (caps_struct, tag_list);
            } else if (name.has_prefix ("audio")) {
                extract_audio_info (caps_struct, tag_list);
            }
        }
    }

    private void extract_audio_info (Structure structure,
                                     TagList tag_list) {
        this.extract_int_value (structure, tag_list,"rate", TAG_RYGEL_RATE);
        this.extract_int_value (structure,
                                tag_list,
                                "channels",
                                TAG_RYGEL_CHANNELS);
    }

    private void extract_video_info (Structure structure, TagList tag_list) {
        this.extract_int_value (structure, tag_list, "depth", TAG_RYGEL_DEPTH);
        this.extract_int_value (structure, tag_list, "width", TAG_RYGEL_WIDTH);
        this.extract_int_value (structure,
                                tag_list,
                                "height",
                                TAG_RYGEL_HEIGHT);
    }

    private void extract_int_value (Structure structure,
                                    TagList   tag_list,
                                    string    key,
                                    string    tag) {
        int val;

        if (structure.get_int (key, out val)) {
            tag_list.add (TagMergeMode.REPLACE, tag, val);
        }
    }
}
