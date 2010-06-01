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

    /* Signals */
    public signal void extraction_done (File file, Gst.TagList tag_list);

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

        this.discoverer = new GUPnP.DLNADiscoverer ((ClockTime)
                                              (this.timeout * 1000000000ULL));
        this.discoverer.done.connect (on_done);
        this.discoverer.start ();
    }

    ~MetadataExtractor () {
        this.discoverer.stop ();
    }

    private void on_done (GUPnP.DLNAProfile profile,
                          GLib.Error        err) {
        assert (this.file_hash.has_key (profile.info.uri));

        File file = this.file_hash.get (profile.info.uri);
        TagList tag_list = new TagList ();

        this.file_hash.unset (profile.info.uri);

        if ((profile.info.result & Gst.DiscovererResult.TIMEOUT) != 0) {
            this.error (file,
                        new IOChannelError.FAILED ("Pipeline stuckwhile" +
                                                   "reading file info"));
            return;
        } else if ((profile.info.result & Gst.DiscovererResult.ERROR) != 0) {
            this.error (file, err);
            return;
        }

        try {
            this.extract_mime_and_size (file, tag_list);
            this.extract_duration (profile.info, tag_list);
            this.extract_stream_info (profile.info, tag_list);
            this.extraction_done (file, tag_list);
        } catch (Error e) {
            debug ("Unable to extract metadata for %s: %s\n",
                   profile.info.uri,
                   err.message);
        }
    }

    public void extract (File file) {
        string uri = file.get_uri ();
        this.file_hash.set (uri, file);
        this.discoverer.discover_uri (uri);
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

    private void extract_duration (Gst.DiscovererInformation info,
                                   TagList                   tag_list) {
        tag_list.add (TagMergeMode.REPLACE,
                      TAG_DURATION,
                      info.duration);
    }

    private void extract_stream_info (Gst.DiscovererInformation info,
                                      TagList                   tag_list) {
        foreach (unowned Gst.StreamInformation i in info.stream_list) {
            if (i.streamtype == Gst.StreamType.VIDEO) {
                extract_video_info ((Gst.StreamVideoInformation) i, tag_list);
            } else if (i.streamtype == Gst.StreamType.AUDIO) {
                extract_audio_info ((Gst.StreamAudioInformation) i, tag_list);
            }
        }
    }

    private void extract_audio_info (Gst.StreamAudioInformation info,
                                     TagList                    tag_list) {
        if (info.sample_rate != 0)
            tag_list.add (TagMergeMode.REPLACE,
                          TAG_RYGEL_RATE,
                          info.sample_rate);
        if (info.channels != 0)
            tag_list.add (TagMergeMode.REPLACE,
                          TAG_RYGEL_CHANNELS,
                          info.channels);
    }

    private void extract_video_info (Gst.StreamVideoInformation info,
                                     TagList                    tag_list) {
        if (info.depth != 0)
            tag_list.add (TagMergeMode.REPLACE,
                          TAG_RYGEL_DEPTH,
                          info.depth);
        if (info.width != 0)
            tag_list.add (TagMergeMode.REPLACE,
                          TAG_RYGEL_WIDTH,
                          info.width);
        if (info.height != 0)
            tag_list.add (TagMergeMode.REPLACE,
                          TAG_RYGEL_HEIGHT,
                          info.height);
    }
}
