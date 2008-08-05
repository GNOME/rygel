/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Gst;
using GUPnP;

private enum Gst.StreamType {
    UNKNOWN = 0,
    AUDIO   = 1,    /* an audio stream */
    VIDEO   = 2,    /* a video stream */
    TEXT    = 3,    /* a subtitle/text stream */
    SUBPICTURE = 4, /* a subtitle in picture-form */
    ELEMENT = 5    /* stream handled by an element */
}

public class GUPnP.MetadataExtractor: GLib.Object {

    /* TODO: Use tagbin instead once it's ready */
    private dynamic Gst.Element playbin;

    /* Signals */
    public signal void metadata_available (string uri,
                                           string key,
                                           ref GLib.Value value);
    public signal void extraction_done (string uri);

    public string uri {
        get {
            return this.playbin.uri;
        }

        set {
            this.playbin.uri = value;

            if (this.playbin.uri != null) {
                /* Start the extaction when we get a new URI */
                this.playbin.set_state (State.PAUSED);
            }
        }
    }

    /* A list of URIs to extract metadata from */
    public List <string> _uris = null;
    public List <string> uris {
        get {
            return this._uris;
        }

        set {
            this._uris = value.copy ();

            if (this._uris != null) {
                this.extraction_done += this.goto_next_uri;
                this.uri = this._uris.data;
            } else {
                this.extraction_done -= this.goto_next_uri;
            }
        }
    }

    private void goto_next_uri (MetadataExtractor extractor,
                                string            uri) {
        return_if_fail (this._uris != null);

        weak List <string> link = this._uris.find_custom (uri, strcmp);
        this._uris.remove_link (link);

        if (this._uris != null) {
            this.uri = this._uris.data;
        } else {
            this.extraction_done -= this.goto_next_uri;
        }
    }

    private void tag_cb (Gst.Bus     bus,
                         Gst.Message message) {
        TagList tag_list;

        message.parse_tag (out tag_list);

        tag_list.foreach (this.foreach_tag);
    }

    private void foreach_tag (TagList tag_list, string tag) {
        GLib.Value value;

        if (tag_list.copy_value (out value, tag_list, tag)) {
            /* signal the availability of new tag */
            this.metadata_available (this.playbin.uri, tag, ref value);
        }
    }

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
            this.playbin.set_state (State.NULL);
            this.extraction_done (this.playbin.uri);
        }
    }

    private void extract_duration () {
        int64 duration;

        Format format = Format.TIME;
        if (this.playbin.query_duration (ref format, out duration)) {
            GLib.Value duration_val;

            duration_val.init (typeof (int64));
            duration_val.set_int64 (duration);

            /* signal the availability of duration tag */
            this.metadata_available (this.playbin.uri,
                    TAG_DURATION,
                    ref duration_val);
        }
    }

    private void extract_stream_info () {
        weak List <dynamic GLib.Object> stream_info = null;

        stream_info = this.playbin.stream_info;
        return_if_fail (stream_info != null);

        for (var i = 0; i < stream_info.length (); i++) {
            dynamic GLib.Object info = stream_info.nth_data (i);

            if (info == null) {
                continue;
            }

            extract_av_info (info);
        }
    }

    private void extract_av_info (dynamic GLib.Object info) {
        Pad pad = (Pad) info.object;
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

        StreamType type = info.type;
        if (type == StreamType.AUDIO) {
            this.extract_audio_info (structure);
        } else if (type == StreamType.VIDEO) {
            this.extract_video_info (structure);
        }
    }

    private void extract_audio_info (Structure structure) {
        this.extract_int_value (structure, "channels");
        this.extract_int_value (structure, "rate");
    }

    private void extract_video_info (Structure structure) {
        this.extract_int_value (structure, "width");
        this.extract_int_value (structure, "height");
    }

    private void extract_int_value (Structure structure, string key) {
        int val;

        if (structure.get_int (key, out val)) {
            GLib.Value value;

            value.init (typeof (int));
            value.set_int (val);

            /* signal the availability of new tag */
            this.metadata_available (this.playbin.uri, key, ref value);
        }
    }

    private void error_cb (Gst.Bus     bus,
                           Gst.Message message) {

        return_if_fail (this.uri != null);

        Error error = null;
        string debug;

        message.parse_error (out error, out debug);
        if (error != null) {
            debug = error.message;
        }

        critical ("Failed to extract metadata from %s: %s\n", this.uri, debug);

        if (this._uris != null) {
            /* We have a list of URIs to harvest, so lets jump to next one */
            this.goto_next_uri (this, this.uri);
        }
    }

    construct {
        this.playbin = ElementFactory.make ("playbin", null);

        var bus = this.playbin.get_bus ();

        bus.add_signal_watch ();

        bus.message["tag"] += this.tag_cb;
        bus.message["state-changed"] += this.state_changed_cb;
        bus.message["error"] += this.error_cb;
    }
}

