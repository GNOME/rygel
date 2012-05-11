/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using GUPnP;

public class Rygel.Playbin.Player : GLib.Object, Rygel.MediaPlayer {
    private const string TRANSFER_MODE_STREAMING = "Streaming";
    private const string TRANSFER_MODE_INTERACTIVE = "Interactive";
    private const string PROTOCOL_INFO_TEMPLATE = "http-get:%s:*:%s";

    private const string[] protocols = { "http-get", "rtsp" };
    private const string[] mime_types = {
                                        "audio/mpeg",
                                        "application/ogg",
                                        "audio/x-vorbis",
                                        "audio/x-vorbis+ogg",
                                        "audio/x-ms-wma",
                                        "audio/x-ms-asf",
                                        "audio/x-flac",
                                        "audio/x-mod",
                                        "audio/x-wav",
                                        "audio/x-ac3",
                                        "audio/x-m4a",
                                        "image/jpeg",
                                        "image/png",
                                        "video/x-theora",
                                        "video/x-dirac",
                                        "video/x-wmv",
                                        "video/x-wma",
                                        "video/x-msvideo",
                                        "video/x-3ivx",
                                        "video/x-3ivx",
                                        "video/x-matroska",
                                        "video/x-mkv",
                                        "video/mpeg",
                                        "video/mp4",
                                        "video/x-ms-asf",
                                        "video/x-xvid",
                                        "video/x-ms-wmv",
                                        "audio/L16;rate=44100;channels=2",
                                        "audio/L16;rate=44100;channels=1" };
    private static Player player;

    private dynamic Element playbin;

    private string _playback_state = "STOPPED";
    public string playback_state {
        owned get {
            return this._playback_state;
        }

        set {
            debug ("Changing playback state to %s.", value);
            this._playback_state = value;

            switch (this._playback_state) {
                case "STOPPED":
                    this.playbin.set_state (State.NULL);
                break;
                case "PAUSED_PLAYBACK":
                    this.playbin.set_state (State.PAUSED);
                break;
                case "PLAYING":
                    this.playbin.set_state (State.PLAYING);
                break;
                default:
                break;
            }
        }
    }

    private string transfer_mode = null;

    public string? uri {
        owned get {
            return this.playbin.uri;
        }

        set {
            this.playbin.set_state (State.NULL);
            this.playbin.uri = value;
            this.playbin.set_state (State.PLAYING);
            debug ("URI set to %s.", value);
        }
    }

    private string _mime_type = "";
    public string? mime_type {
        owned get {
            return this._mime_type;
        }

        set {
            this._mime_type = value;
        }
    }

    private string _metadata = "";
    public string? metadata {
        owned get {
            return this._metadata;
        }

        set {
            this._metadata = value;
        }
    }

    private string _content_features = "";
    private ProtocolInfo protocol_info;
    public string? content_features {
        owned get {
            return this._content_features;
        }

        set {
            var pi_string = PROTOCOL_INFO_TEMPLATE.printf (this.mime_type,
                                                           value);
            try {
                this.protocol_info = new ProtocolInfo.from_string (pi_string);
                var flags = this.protocol_info.dlna_flags;
                if (DLNAFlags.INTERACTIVE_TRANSFER_MODE in flags) {
                    this.transfer_mode = TRANSFER_MODE_INTERACTIVE;
                } else if (DLNAFlags.STREAMING_TRANSFER_MODE in flags) {
                    this.transfer_mode = TRANSFER_MODE_STREAMING;
                } else {
                    this.transfer_mode = null;
                }
            } catch (Error error) {
                this.protocol_info = null;
                this.transfer_mode = null;
            }
            this._content_features = value;
        }
    }

    public double volume {
        get {
            return this.playbin.volume;
        }

        set {
            this.playbin.volume = value;
            debug ("volume set to %f.", value);
        }
    }

    public int64 duration {
        get {
            var format = Format.TIME;
            int64 dur;

            if (this.playbin.query_duration (ref format, out dur)) {
                return dur;
            } else {
                return 0;
            }
        }
    }

    public int64 position {
        get {
            var format = Format.TIME;
            int64 pos;

            if (this.playbin.query_position (ref format, out pos)) {
                return pos;
            } else {
                return 0;
            }
        }
    }

    private Player () {
        this.playbin = ElementFactory.make ("playbin2", null);
        assert (this.playbin != null);

        playbin.source_setup.connect (this.on_source_setup);

        // Bus handler
        var bus = this.playbin.get_bus ();
        bus.add_watch (this.bus_handler);
    }

    public static Player get_default () {
        if (player == null) {
            player = new Player ();
        }

        return player;
    }

    public bool seek (ClockTime time) {
        return this.playbin.seek (1.0,
                                  Format.TIME,
                                  SeekFlags.FLUSH,
                                  Gst.SeekType.SET,
                                  (int64) time,
                                  Gst.SeekType.NONE,
                                  -1);
    }

    public string[] get_protocols () {
        return protocols;
    }

    public string[] get_mime_types () {
        return mime_types;
    }

    private bool is_rendering_image () {
        dynamic Element typefind;

        typefind = (this.playbin as Gst.Bin).get_by_name ("typefind");
        Caps caps = typefind.caps;
        var structure = caps.get_structure (0);

        return structure.get_name () == "image/jpeg" ||
               structure.get_name () == "image/png";
    }

    private bool bus_handler (Gst.Bus bus,
                              Message message) {
        switch (message.type) {
        case MessageType.STATE_CHANGED:
            if (message.src == this.playbin) {
                State old_state, new_state;

                message.parse_state_changed (out old_state, out new_state, null);
                if (old_state == State.READY && new_state == State.PAUSED) {
                    this.notify_property ("duration");
                }
            }
            break;
        case MessageType.EOS:
            if (!this.is_rendering_image ()) {
                debug ("EOS");
                this.playback_state = "STOPPED";
            } else {
                debug ("Content is image, ignoring EOS");
            }

            break;
        case MessageType.ERROR:
            Error error;
            string error_message;

            message.parse_error (out error, out error_message);

            warning ("Error from GStreamer element %s: %s",
                     this.playbin.name,
                     error_message);
            warning ("Going to STOPPED state");

            this.playback_state = "STOPPED";

            break;
        }

        return true;
    }

    private void on_source_setup (Element pipeline, dynamic Element source) {
        if (source.get_type ().name () == "GstSoupHTTPSrc" &&
            this.transfer_mode != null) {
            debug ("Setting transfer mode to %s", this.transfer_mode);

            var structure = new Structure.empty ("Extra Headers");
            structure.set_value ("transferMode.dlna.org", this.transfer_mode);

            source.extra_headers = structure;
        }
    }
}
