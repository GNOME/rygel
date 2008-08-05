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

        if (tag_list.copy_value (ref value, tag_list, tag)) {
            /* signal the availability of new tag */
            this.metadata_available (this.playbin.uri, tag, ref value);
        }
    }

    private void state_changed_cb (Gst.Bus     bus,
                                   Gst.Message message) {
        if (message.src != this.playbin)
            return;

        State new_state;

        message.parse_state_changed (null, out new_state, null);
        if (new_state == State.PAUSED) {
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

            /* No hopes of getting any tags after this point */
            this.playbin.set_state (State.NULL);
            this.extraction_done (this.playbin.uri);
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

