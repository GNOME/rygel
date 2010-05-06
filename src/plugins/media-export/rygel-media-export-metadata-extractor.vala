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

private enum Gst.StreamType {
    UNKNOWN = 0,
    AUDIO   = 1,    /* an audio stream */
    VIDEO   = 2,    /* a video stream */
    TEXT    = 3,    /* a subtitle/text stream */
    SUBPICTURE = 4, /* a subtitle in picture-form */
    ELEMENT = 5     /* stream handled by an element */
}

/**
 * Metadata extractor based on Gstreamer. Just set the URI of the media on the
 * uri property, it will extact the metadata for you and emit signal
 * metadata_available for each key/value pair extracted.
 */
public class Rygel.MediaExportMetadataExtractor: GLib.Object {
    public const string TAG_RYGEL_SIZE = "rygel-size";
    public const string TAG_RYGEL_DURATION = "rygel-duration";
    public const string TAG_RYGEL_MIME = "rygel-mime";
    public const string TAG_RYGEL_CHANNELS = "rygel-channels";
    public const string TAG_RYGEL_RATE = "rygel-rate";
    public const string TAG_RYGEL_WIDTH = "rygel-width";
    public const string TAG_RYGEL_HEIGHT = "rygel-height";
    public const string TAG_RYGEL_DEPTH = "rygel-depth";
    public const string TAG_RYGEL_MTIME = "rygel-mtime";

    /* TODO: Use tagbin instead once it's ready */
    private dynamic Gst.Element playbin;

    /* Signals */
    public signal void extraction_done (File file, Gst.TagList tag_list);

    /**
     * Signalize that an error occured during metadata extraction
     */
    public signal void error (File file, Error err);

    private TagList tag_list;

    private GLib.Queue<File> file_queue;

    private uint timeout_id;

    private static ElementFactory factory;

    private static void register_custom_tag (string tag, Type type) {
        Gst.tag_register (tag,
                          TagFlag.META,
                          type,
                          tag,
                          "",
                          Gst.tag_merge_use_first);
    }

    private void renew_playbin () {
        // setup fake sinks
        this.playbin = this.factory.create ("tag_reader");

        // increase reference count of sinks to workaround
        // bug #596078
        var sink = ElementFactory.make ("fakesink", null);
        sink.ref ();
        this.playbin.video_sink = sink;

        sink = ElementFactory.make ("fakesink", null);
        sink.ref ();
        this.playbin.audio_sink = sink;

        var bus = this.playbin.get_bus ();
        bus.add_signal_watch ();
        bus.message["tag"] += this.tag_cb;
        if (factory.get_element_type ().name () == "GstPlayBin2") {
            bus.message["element"] += this.element_message_cb;
        } else {
            bus.message["state-changed"] += this.state_changed_cb;
        }
        bus.message["error"] += this.error_cb;
    }

    public static MediaExportMetadataExtractor? create() {
        if (MediaExportMetadataExtractor.factory == null) {
            debug ("Checking for gstreamer element 'playbin'...");
            var factory = ElementFactory.find("playbin2");
            if (factory != null) {
                debug (_("Using playbin2"));
            } else {
                debug (_("Could not create Playbin2, trying Playbin"));
                factory = ElementFactory.find ("playbin");

                if (factory != null) {
                    debug (_("Using playbin"));
                } else {
                    critical (_("Could not find any playbin.") + " " +
                              _("Please check your gstreamer setup"));
                    return null;
                }
            }
            MediaExportMetadataExtractor.factory = factory;
        }

        return new MediaExportMetadataExtractor ();
    }

    MediaExportMetadataExtractor () {
        this.register_custom_tag (TAG_RYGEL_SIZE, typeof (int64));
        this.register_custom_tag (TAG_RYGEL_DURATION, typeof (int64));
        this.register_custom_tag (TAG_RYGEL_MIME, typeof (string));
        this.register_custom_tag (TAG_RYGEL_CHANNELS, typeof (int));
        this.register_custom_tag (TAG_RYGEL_RATE, typeof (int));
        this.register_custom_tag (TAG_RYGEL_WIDTH, typeof (int));
        this.register_custom_tag (TAG_RYGEL_HEIGHT, typeof (int));
        this.register_custom_tag (TAG_RYGEL_DEPTH, typeof (int));
        this.register_custom_tag (TAG_RYGEL_MTIME, typeof (uint64));

        this.file_queue = new GLib.Queue<File> ();
        this.tag_list = new Gst.TagList ();
    }

    public void extract (File file) {
        var trigger_run = this.file_queue.get_length () == 0;
        this.file_queue.push_tail (file);
        if (trigger_run) {
            this.extract_next ();
        }
    }

    private bool on_harvesting_timeout () {
        warning (_("Metadata extractor timed out on %s, restarting"),
                 this.file_queue.peek_head ().get_uri ());
        this.playbin.set_state (State.NULL);

        var message = _("Pipeline stuck while reading file info");
        this.error (file_queue.peek_head (),
                    new IOChannelError.FAILED (message));
        this.file_queue.pop_head ();
        extract_next ();
        return false;
    }

    private void extract_next () {
        if (this.timeout_id != 0)
            Source.remove (this.timeout_id);

        if (this.file_queue.get_length () > 0) {
            try {
                var item = this.file_queue.peek_head ();
                debug (_("Scheduling file %s for metadata extraction"),
                       item.get_uri ());
                this.extract_mime_and_size ();
                renew_playbin ();
                this.playbin.uri = item.get_uri ();
                this.timeout_id = Timeout.add_seconds_full (
                                                         Priority.DEFAULT,
                                                         5,
                                                         on_harvesting_timeout);
                this.playbin.set_state (State.PAUSED);
            } catch (Error error) {
                // on error just move to the next uri in queue
                this.extract_next ();
            }
        }
    }

    /* Callback for tags found by playbin */
    private void tag_cb (Gst.Bus     bus,
                         Gst.Message message) {
        TagList new_tag_list;

        message.parse_tag (out new_tag_list);
        this.tag_list = new_tag_list.merge (this.tag_list,
                                            TagMergeMode.REPLACE);
    }

    private void element_message_cb (Bus     bus,
                                     Message message) {
        if (message.src != this.playbin) {
            return;
        }

        if (message.structure.get_name () == "playbin2-stream-changed") {
            this.extract_duration ();
            this.extract_stream_info ();

            /* No hopes of getting any tags after this point */
            this.extraction_done (this.file_queue.peek_head (), tag_list);
            this.playbin.set_state (State.NULL);
            this.tag_list = new Gst.TagList ();
            this.file_queue.pop_head ();
            this.extract_next ();
        }
    }

    /* Callback for state-change in playbin */
    private void state_changed_cb (Gst.Bus     bus,
                                   Gst.Message message) {
        if (message.src != this.playbin)
            return;

        State new_state;
        State old_state;

        message.parse_state_changed (out old_state, out new_state, null);
        if (new_state == State.PAUSED && old_state == State.READY) {
            this.extract_duration ();
            this.extract_stream_info ();

            /* No hopes of getting any tags after this point */
            this.extraction_done (this.file_queue.peek_head (), tag_list);
            this.playbin.set_state (State.NULL);
            this.tag_list = new Gst.TagList ();
            this.file_queue.pop_head ();
            this.extract_next ();
        }
    }

    /* Callback for errors in playbin */
    private void error_cb (Gst.Bus     bus,
                           Gst.Message message) {

        return_if_fail (this.file_queue.get_length() != 0);

        Error error = null;
        string debug;

        message.parse_error (out error, out debug);
        if (error != null) {
            debug = error.message;
        }

        // signalize error to listeners
        this.error (this.file_queue.peek_head (), error);

        /* We have a list of URIs to harvest, so lets jump to next one */
        this.playbin.set_state (State.NULL);
        this.tag_list = new Gst.TagList ();
        this.file_queue.pop_head ();
        this.extract_next ();
    }

    private void extract_mime_and_size () throws Error {
        var file = this.file_queue.peek_head ();
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

        weak string content_type = file_info.get_content_type ();
        weak string mime = g_content_type_get_mime_type (content_type);
        if (mime != null) {
            /* add custom mime tag to tag list */
            this.tag_list.add (TagMergeMode.REPLACE,
                               TAG_RYGEL_MIME,
                               mime);
        }

        var size = file_info.get_size ();
        this.tag_list.add (TagMergeMode.REPLACE,
                           TAG_RYGEL_SIZE,
                           size);

        var mtime = file_info.get_attribute_uint64(
                                                FILE_ATTRIBUTE_TIME_MODIFIED);
        this.tag_list.add (TagMergeMode.REPLACE,
                           TAG_RYGEL_MTIME,
                           mtime);
    }

    private void extract_duration () {
        int64 duration;

        Format format = Format.TIME;
        if (this.playbin.query_duration (ref format, out duration)) {
            this.tag_list.add (TagMergeMode.REPLACE,
                               TAG_RYGEL_DURATION,
                               duration);
        }
    }

    private void extract_stream_info () {
        extract_av_info (this.playbin.video_sink.get_pad ("sink"),
                StreamType.VIDEO);
        extract_av_info (this.playbin.audio_sink.get_pad ("sink"),
                StreamType.AUDIO);
    }

    private void extract_av_info (Pad pad, StreamType type) {
        if (pad == null) {
            return;
        }

        Gst.Caps caps = pad.get_negotiated_caps ();
        if (caps == null) {
            return;
        }

        weak Structure structure = caps.get_structure (0);
        if (structure == null) {
            return;
        }

        if (type == StreamType.AUDIO) {
            this.extract_audio_info (structure);
        } else if (type == StreamType.VIDEO) {
            this.extract_video_info (structure);
        }
    }

    private void extract_audio_info (Structure structure) {
        this.extract_int_value (structure, "channels", TAG_RYGEL_CHANNELS);
        this.extract_int_value (structure, "rate", TAG_RYGEL_RATE);
    }

    private void extract_video_info (Structure structure) {
        this.extract_int_value (structure, "width", TAG_RYGEL_WIDTH);
        this.extract_int_value (structure, "height", TAG_RYGEL_HEIGHT);
        this.extract_int_value (structure, "depth", TAG_RYGEL_DEPTH);
    }

    private void extract_int_value (Structure structure,
                                    string key,
                                    string tag) {
        int val;

        if (structure.get_int (key, out val)) {
            tag_list.add (TagMergeMode.REPLACE,
                          tag,
                          val);
        }
    }
}
