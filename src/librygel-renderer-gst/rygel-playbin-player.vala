/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009,2010,2011,2012 Nokia Corporation.
 * Copyright (C) 2012 Openismus GmbH
 * Copyright (C) 2012,2013 Intel Corporation.
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Neha Shanbhag <N.Shanbhag@cablelabs.com>
 *         Sivakumar Mani <siva@orexel.com>
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
using GUPnP;

public errordomain Rygel.PlaybinPlayerError {
    NO_ELEMENT
}

/**
 * Implementation of RygelMediaPlayer for GStreamer.
 *
 * This class is useful only when implementing Rygel plugins.
 */
public class Rygel.PlaybinPlayer : GLib.Object, Rygel.MediaPlayer {
    private const string TRANSFER_MODE_STREAMING = "Streaming";
    private const string TRANSFER_MODE_INTERACTIVE = "Interactive";
    private const string PROTOCOL_INFO_TEMPLATE = "http-get:%s:*:%s";

    private const string[] protocols = { "http-get", "rtsp" };
    private const string[] mime_types = {
                                        "audio/mpeg",
                                        "application/ogg",
                                        "audio/x-vorbis",
                                        "audio/x-vorbis+ogg",
                                        "audio/ogg",
                                        "audio/x-ms-wma",
                                        "audio/x-ms-asf",
                                        "audio/x-flac",
                                        "audio/x-flac+ogg",
                                        "audio/flac",
                                        "audio/mp4",
                                        "audio/3gpp",
                                        "audio/vnd.dlna.adts",
                                        "audio/x-mod",
                                        "audio/x-wav",
                                        "audio/wav",
                                        "audio/x-ac3",
                                        "audio/x-m4a",
                                        "audio/aac",
                                        "audio/l16;rate=44100;channels=2",
                                        "audio/l16;rate=44100;channels=1",
                                        "audio/l16;channels=2;rate=44100",
                                        "audio/l16;channels=1;rate=44100",
                                        "audio/l16;rate=44100",
                                        "image/jpeg",
                                        "image/png",
                                        "video/x-theora",
                                        "video/x-theora+ogg",
                                        "video/x-oggm",
                                        "video/ogg",
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
                                        "video/avi",
                                        "application/x-shockwave-flash",
                                        "video/x-ms-asf",
                                        "video/x-xvid",
                                        "video/x-ms-wmv" };
    private static PlaybinPlayer player;
    private static bool has_dlna_src;

    static construct {
        PlaybinPlayer.has_dlna_src = Gst.Uri.protocol_is_supported (URIType.SRC,
                                                                   "dlna+http");
    }

    public dynamic Element playbin { get; private set; }

    private string _playback_state = "NO_MEDIA_PRESENT";
    public string playback_state {
        owned get {
            return this._playback_state;
        }

        set {
            Gst.State state, pending;

            this.playbin.get_state (out state, out pending, Gst.MSECOND);

            debug ("Changing playback state to %s.", value);

            switch (value) {
                case "STOPPED":
                    if (state != State.NULL || pending != State.VOID_PENDING) {
                        this.playbin.set_state (State.NULL);
                    } else {
                        this._playback_state = value;
                    }
                break;
                case "PAUSED_PLAYBACK":
                    if (state != State.PAUSED || pending != State.VOID_PENDING) {
                        this.playbin.set_state (State.PAUSED);
                    } else {
                        this._playback_state = value;
                    }
                break;
                case "PLAYING":
                    if (this._new_playback_speed != this._playback_speed &&
                        (state == State.PLAYING || state == State.PAUSED) &&
                        pending == State.VOID_PENDING) {
                        /* already playing, but play speed has changed */
                        this._playback_state = "TRANSITIONING";
                        this.seek (this.position);
                    } else if (state != State.PLAYING ||
                               pending != State.VOID_PENDING) {
                        // This needs a check if GStreamer and DLNA agree on
                        // the "liveness" of the source (s0/sn increase in
                        // protocol info)
                        this._playback_state = "TRANSITIONING";
                        this.playbin.set_state (State.PLAYING);
                    } else {
                        this._playback_state = value;
                    }
                break;
                case "EOS":
                    this._playback_state = value;
                break;
                default:
                break;
            }
        }
    }

    private string[] _allowed_playback_speeds = {
        "1/16", "1/8", "1/4", "1/2", "1", "2", "4", "8", "16", "32", "64"
    };
    public string[] allowed_playback_speeds {
        owned get {
            return this._allowed_playback_speeds;
        }
    }

    /**
     * Actual _playback_speed is updated when playbin seek succeeds.
     * Until that point, the playback speed set via api is stored in
     * _new_playback_speed.
     **/
    private string _new_playback_speed = "1";

    private string _playback_speed = "1";
    public string playback_speed {
        owned get {
            return this._playback_speed;
        }

        set {
            this._new_playback_speed = value;
            /* theoretically we should trigger a seek here if we were
             * playing already, but playback state does get changed
             * after this when "Play" is invoked... */
        }
    }

    private string transfer_mode = null;

    private bool uri_update_hint = false;
    private string? _uri = null;
    public string? uri {
        owned get {
            return _uri;
        }

        set {
            this._uri = value;
            this.playbin.set_state (State.READY);
            if (PlaybinPlayer.has_dlna_src && value.has_prefix ("http")) {
                debug ("Trying to use DLNA src element");
                this.playbin.uri = "dlna+" + value;
            } else {
                this.playbin.uri = value;
            }

            if (value != "") {
                this.guess_duration ();
                switch (this._playback_state) {
                    case "NO_MEDIA_PRESENT":
                        this._playback_state = "STOPPED";
                        this.notify_property ("playback-state");
                        break;
                    case "STOPPED":
                        break;
                    case "PAUSED_PLAYBACK":
                        this.playbin.set_state (State.PAUSED);
                        break;
                    case "EOS":
                    case "PLAYING":
                        this.playbin.set_state (State.PLAYING);
                        break;
                    default:
                        break;
                }
            } else {
                this._playback_state = "NO_MEDIA_PRESENT";
                this.notify_property ("playback-state");
            }
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
            this._parsed_duration = 0;
            this._metadata = value;
        }
    }

    public bool can_seek {
        get {
            return this.transfer_mode != TRANSFER_MODE_INTERACTIVE &&
                   ! this.mime_type.has_prefix ("image/");
        }
    }

    public bool can_seek_bytes {
        get {
            return this.transfer_mode != TRANSFER_MODE_INTERACTIVE &&
                   ! this.mime_type.has_prefix ("image/");
        }
    }

    public string? user_agent { owned get; set; }

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
            return ((Audio.StreamVolume) this.playbin).get_volume
                                        (Audio.StreamVolumeFormat.CUBIC);
        }

        set {
            ((Audio.StreamVolume) this.playbin).set_volume
                                        (Audio.StreamVolumeFormat.CUBIC, value);
            debug ("volume set to %f.", value);
        }
    }

    private int64 _parsed_duration;
    public int64 duration {
        get {
            int64 dur = 0;

            if (this.playbin.query_duration (Format.TIME, out dur)) {
                return dur / Gst.USECOND;
            } else {
                return _parsed_duration;
            }
        }
    }

    public int64 size {
        get {
            int64 dur = 0;

            if (this.source != null &&
                this.source.query_duration (Format.BYTES, out dur)) {
                return dur;
            } else {
                return 0;
            }
        }
    }

    public int64 position {
        get {
            int64 pos;

            if (this.playbin.query_position (Format.TIME, out pos)) {
                return pos / Gst.USECOND;
            } else {
                return 0;
            }
        }
    }

    public int64 byte_position {
       get {
            int64 pos = 0;

            if (this.source != null &&
                this.source.query_position (Format.BYTES, out pos)) {
                return pos;
            } else {
                return 0;
            }
        }
    }

    private PlaybinPlayer () throws Error {
        this.playbin = ElementFactory.make ("playbin3", null);
        if (this.playbin == null) {
            throw new PlaybinPlayerError.NO_ELEMENT (
                _("Your GStreamer installation seems to be missing the “playbin3” element. The Rygel GStreamer renderer implementation cannot work without it"));
        }
        this.setup_playbin ();
    }

    public static PlaybinPlayer instance () throws Error {
        if (player == null) {
            player = new PlaybinPlayer ();
        }

        return player;
    }

    private bool seek_with_format (Format format, int64 target) {
        bool seeked;

        var speed = this.play_speed_to_double (this._new_playback_speed);
        if (speed > 0) {
            seeked = this.playbin.seek (speed,
                                        format,
                                        SeekFlags.FLUSH | SeekFlags.SKIP | SeekFlags.ACCURATE,
                                        Gst.SeekType.SET,
                                        target,
                                        Gst.SeekType.NONE,
                                        -1);
        } else {
            seeked = this.playbin.seek (speed,
                                        format,
                                        SeekFlags.FLUSH | SeekFlags.SKIP | SeekFlags.ACCURATE,
                                        Gst.SeekType.SET,
                                        0,
                                        Gst.SeekType.SET,
                                        target);
        }
        if (seeked) {
            this._playback_speed = this._new_playback_speed;
        }

        return seeked;
    }

    public bool seek (int64 time) {
        debug ("Seeking %lld usec, play speed %s", time, this._new_playback_speed);

        // Playbin doesn't return false when seeking beyond the end of the
        // file
        if (time > this.duration) {
            return false;
        }

        return this.seek_with_format (Format.TIME, time * Gst.USECOND);
    }

    public bool seek_bytes (int64 bytes) {
        debug ("Seeking %lld bytes, play speed %s", bytes, this._new_playback_speed);

        int64 size = this.size;
        if (size > 0 && bytes > size) {
            return false;
        }

        return this.seek_with_format (Format.BYTES, bytes);
    }

    public string[] get_protocols () {
        return protocols;
    }

    public string[] get_mime_types () {
        return mime_types;
    }

    private GLib.List<DLNAProfile> _supported_profiles;
    public unowned GLib.List<DLNAProfile> supported_profiles {
        get {
            if (_supported_profiles == null) {
                // FIXME: Check available decoders in registry and register
                // profiles after that
                _supported_profiles = new GLib.List<DLNAProfile> ();

                // Image
                _supported_profiles.prepend (new DLNAProfile ("JPEG_SM",
                                                              "image/jpeg"));
                _supported_profiles.prepend (new DLNAProfile ("JPEG_MED",
                                                              "image/jpeg"));
                _supported_profiles.prepend (new DLNAProfile ("JPEG_LRG",
                                                              "image/jpeg"));
                _supported_profiles.prepend (new DLNAProfile ("PNG_LRG",
                                                              "image/png"));

                // Audio
                _supported_profiles.prepend (new DLNAProfile ("MP3",
                                                              "audio/mpeg"));
                _supported_profiles.prepend (new DLNAProfile ("MP3X",
                                                              "audio/mpeg"));
                _supported_profiles.prepend (new DLNAProfile
                                        ("AAC_ADTS_320",
                                         "audio/vnd.dlna.adts"));
                _supported_profiles.prepend (new DLNAProfile ("AAC_ISO_320",
                                                              "audio/mp4"));
                _supported_profiles.prepend (new DLNAProfile ("AAC_ISO_320",
                                                              "audio/3gpp"));
                _supported_profiles.prepend (new DLNAProfile
                                        ("LPCM",
                                         "audio/l16;rate=44100;channels=2"));
                _supported_profiles.prepend (new DLNAProfile
                                        ("LPCM",
                                         "audio/l16;rate=44100;channels=1"));
                _supported_profiles.prepend (new DLNAProfile ("WMABASE",
                                                              "audio/x-ms-wma"));
                _supported_profiles.prepend (new DLNAProfile ("WMAFULL",
                                                              "audio/x-ms-wma"));
                _supported_profiles.prepend (new DLNAProfile ("WMAPRO",
                                                              "audio/x-ms-wma"));

                // Video
                _supported_profiles.prepend (new DLNAProfile
                                        ("MPEG_TS_SD_EU_ISO",
                                         "video/mpeg"));
                _supported_profiles.prepend (new DLNAProfile
                                        ("MPEG_TS_SD_NA_ISO",
                                         "video/mpeg"));
                _supported_profiles.prepend (new DLNAProfile
                                        ("MPEG_TS_HD_NA_ISO",
                                         "video/mpeg"));
                _supported_profiles.prepend (new DLNAProfile
                                        ("AVC_MP4_BL_CIF15_AAC_520",
                                         "video/mp4"));
            }

            return _supported_profiles;
        }
    }

    private bool is_rendering_image () {
        dynamic Element typefind;

        typefind = ((Gst.Bin) this.playbin).get_by_name ("typefind");
        Caps caps = typefind.caps;
        unowned Structure structure = caps.get_structure (0);

        return structure.get_name () == "image/jpeg" ||
               structure.get_name () == "image/png";
    }

    private void bus_handler (Gst.Bus bus,
                              Message message) {
        switch (message.type) {
        case MessageType.DURATION_CHANGED:
            if (this.playbin.query_duration (Format.TIME, null)) {
                this.notify_property ("duration");
            }
        break;
        case MessageType.STATE_CHANGED:
            if (message.src == this.playbin) {
                State old_state, new_state, pending;

                message.parse_state_changed (out old_state,
                                             out new_state,
                                             out pending);
                if (old_state == State.READY && new_state == State.PAUSED) {
                    if (this.uri_update_hint) {
                        this.uri_update_hint = false;
                        string uri = this.playbin.current_uri;
                        if (this._uri != uri && uri != "") {
                            // uri changed externally
                            this._uri = this.playbin.uri;
                            this.notify_property ("uri");
                            this.metadata = this.generate_basic_didl ();
                        }
                    }

                    if (this.playbin.query_duration (Format.TIME, null)) {
                        this.notify_property ("duration");
                    }
                }

                if (pending == State.VOID_PENDING) {
                    switch (new_state) {
                        case State.PAUSED:
                            this.playback_state = "PAUSED_PLAYBACK";
                            break;
                        case State.NULL:
                            this.playback_state = "STOPPED";
                            break;
                        case State.PLAYING:
                            this.playback_state = "PLAYING";
                            break;
                        default:
                            break;
                    }
                }

                if (old_state == State.PAUSED && new_state == State.PLAYING) {
                    this.playback_state = "PLAYING";
                }
            }
            break;
        case MessageType.EOS:
            if (!this.is_rendering_image ()) {
                debug ("EOS");
                this.playback_state = "EOS";
            } else {
                debug ("Content is image, ignoring EOS");
            }

            break;
        case MessageType.ERROR:
            Error error;
            string debug_message;

            message.parse_error (out error, out debug_message);

            warning ("Error from GStreamer element %s: %s (%s)",
                     this.playbin.name,
                     error.message,
                     debug_message);
            warning ("Going to STOPPED state");

            this.playback_state = "STOPPED";

            break;
        default:
            break;
        }
    }

    private Element source;
    private void on_source_setup (Element pipeline, dynamic Element source) {
        if (source.get_type ().name () == "GstSoupHTTPSrc" &&
            this.transfer_mode != null) {
            debug ("Setting transfer mode to %s", this.transfer_mode);

            var structure = new Structure.empty ("HTTPHeaders");
            structure.set_value ("transferMode.dlna.org", this.transfer_mode);

            source.extra_headers = structure;
            source.user_agent = this.user_agent;
        }

        this.source = source;
    }

    private void on_uri_notify (ParamSpec pspec) {
        this.uri_update_hint = true;
    }

    /**
     * Generate basic DIDLLite information.
     *
     * This is used when the URI gets changed externally. DLNA requires that a
     * minimum DIDLLite is always present if the URI is not empty.
     */
    private string generate_basic_didl () {
        var writer = new DIDLLiteWriter (null);
        var item = writer.add_item ();
        item.id = "1";
        item.parent_id = "-1";
        item.upnp_class = "object.item";
        var resource = item.add_resource ();
        resource.uri = this._uri;
        var file = File.new_for_uri (this.uri);
        item.title = file.get_basename ();

        return writer.get_string ();
    }

    private void setup_playbin () {
        try {
            var config = MetaConfig.get_default ();
            var sink_launch = config.get_string ("Playbin", "audio-sink");
            debug ("Trying to parse audio sink %s", sink_launch);
            var sink = Gst.parse_bin_from_description (sink_launch,
                                                       true,
                                                       null,
                                                       ParseFlags.FATAL_ERRORS);
            this.playbin.audio_sink = sink;
        } catch (Error error) {
           debug ("No audio sink configured, using default: %s", error.message);
        }

        try {
            var config = MetaConfig.get_default ();
            var sink_launch = config.get_string ("Playbin", "video-sink");
            debug ("Trying to parse video sink %s", sink_launch);
            var sink = Gst.parse_bin_from_description (sink_launch,
                                                       true,
                                                       null,
                                                       ParseFlags.FATAL_ERRORS);
            this.playbin.video_sink = sink;
        } catch (Error error) {
           debug ("No video sink configured, using default: %s", error.message);
        }

        // Needed to get "Stop" events from the playbin.
        // We can do this because we have a bus watch
        this.playbin.auto_flush_bus = false;

        this.playbin.source_setup.connect (this.on_source_setup);
        this.playbin.notify["uri"].connect (this.on_uri_notify);

        this.volume = 0.5;

        // Bus handler
        var bus = this.playbin.get_bus ();
        bus.add_signal_watch ();
        bus.message.connect (this.bus_handler);
    }

    private void guess_duration () {
        if (this._metadata == null || this._metadata == "") {
            return;
        }

        var reader = new DIDLLiteParser ();

        // Try to guess duration from meta-data.
        reader.object_available.connect ( (object) => {
            var resources = object.get_resources ();
            foreach (var resource in resources) {
                if (this._uri == resource.uri && resource.duration > 0) {
                    this._parsed_duration = resource.duration * TimeSpan.SECOND;
                    this.notify_property ("duration");
                }
            }
        });

        try {
            reader.parse_didl (this._metadata);
        } catch (Error error) {
            debug ("Failed to parse meta-data: %s", error.message);
        }
    }
}
