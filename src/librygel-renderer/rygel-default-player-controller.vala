/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2014 Atlantic PuffinPack AB.
 *
 * Author: Richard Röjfors <richard@puffinpack.se>
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

using GUPnP;

/**
 * This class keeps track of global states that are not dependant on the
 * RygelMediaPlayer.
 *
 * These states are:
 * # URI
 * # MetaData
 * # Number of tracks
 * # Current track
 * # Playback state
 *
 * In case of playlists this class will also control the player. It needs to
 * proxy the playback state to react on end of item to be able to switch to
 * the next item.
 */
internal class Rygel.DefaultPlayerController : Rygel.PlayerController, Object {
    private const int DEFAULT_IMAGE_TIMEOUT = 15;
    private const string CONFIG_SECTION = "Renderer";
    private const string TIMEOUT_KEY = "image-timeout";
    private const string DIDL_FRAME_TEMPLATE = "<DIDL-Lite " +
        "xmlns:dc=\"http://purl.org/dc/elements/1.1/\" " +
        "xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" " +
        "xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0/\" " +
        "xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\">" +
        "%s</DIDL-Lite>";

    /* private (construction) properties */
    public MediaPlayer player { construct; private get; }
    public string protocol_info { construct; private get; }

    /* public properties */

    /* this._playback_state mirrors player.playback_state without including
     * non-UPnP "EOS" value. It is updated from notify_state_cb */
    [CCode (notify = false)]
    public string playback_state {
        get { return this._playback_state; }
        set { this.player.playback_state = value; }
    }

    [CCode (notify = false)]
    public uint n_tracks {
        get { return this._n_tracks; }
        protected set {
            if (value != this._n_tracks) {
                this._n_tracks = value;
                this.notify_property ("n-tracks");
            }
        }
    }

    [CCode (notify = false)]
    public uint track {
        get { return this._track; }
        set {
            if (value != this._track) {
                this._track = value;
                this.apply_track ();
                this.notify_property ("track");
            }
        }
    }

    public string uri { owned get; protected set; default = ""; }
    public string metadata { owned get; protected set; default = ""; }

    [CCode (notify = false)]
    public string track_uri {
        owned get {
            if (this.player.uri != null) {
                return Markup.escape_text (this.player.uri);
            } else {
                return "";
            }
        }

        protected set {
            this.player.uri = value;
        }
    }

    [CCode (notify = false)]
    public string track_metadata {
        owned get { return this.player.metadata ?? ""; }

        protected set {
            if (value.has_prefix ("&lt;")) {
                this.player.metadata = this.unescape (value);
            } else {
                this.player.metadata = value;
            }
        }
    }

    public string next_uri { owned get; protected set; default = ""; }
    public string next_metadata { owned get; protected set; default = ""; }

    public bool can_pause {
        get {
            if (this.playback_state != "PLAYING" &&
                this.playback_state != "TRANSITIONING") {
                return false;
            }

            /* Pause is valid for images only in playlist */
            return (!(this.player.mime_type != null &&
                      this.player.mime_type.has_prefix ("image/")) ||
                    this.playlist != null);
        }
    }

    public string current_transport_actions {
        owned get {
            string actions = null;
            switch (this.playback_state) {
                case "PLAYING":
                case "TRANSITIONING":
                    actions = "Stop";
                    /* Pause is valid for images only in playlist */
                    if (!(this.player.mime_type != null &&
                      this.player.mime_type.has_prefix ("image/")) ||
                      this.playlist != null) {
                        actions += ",Pause";
                    }
                    break;
                case "STOPPED":
                    actions = "Play";
                    break;
                case "PAUSED_PLAYBACK":
                    actions = "Stop,Play";
                    break;
                default:
                    break;
            }

            if (actions == null) {
                return "";
            }

            if (this.track < this.n_tracks) {
                actions += ",Next";
            }
            if (this.track > 1) {
                actions += ",Previous";
            }

            if (this.player.can_seek) {
                actions += ",Seek,X_DLNA_SeekTime";
            }
            if (this.player.can_seek_bytes) {
                actions += ",X_DLNA_SeekByte";
            }

            if (this.player.mime_type != null && !this.player.mime_type.has_prefix ("image/") &&
                this.player.allowed_playback_speeds.length > 1) {
                string play_speeds = "";
                foreach (var speed in this.player.allowed_playback_speeds) {
                    if (speed != "1") {
                        if (play_speeds == "") {
                            play_speeds = ",X_DLNA_PS=" + speed;
                        } else {
                            play_speeds += "\\," + speed;
                        }
                    }
                }
                actions += play_speeds;
            }

            return actions;
        }
    }

    [CCode (notify = false)]
    public string play_mode {
        get {
            return this._play_mode;
        }

        set {
            if (value != this._play_mode) {
                this._play_mode = value;
                this.notify_property ("play-mode");
            }
        }
    }

    // Private members
    private List<DIDLLiteItem> playlist;
    private uint timeout_id;
    private uint default_image_timeout;
    private Configuration config;

    private string next_features;
    private string next_mime;
    private MediaCollection next_collection;

    // Private property variables
    private uint _n_tracks = 0U;
    private uint _track = 0U;
    private string _playback_state = "NO_MEDIA_PRESENT";
    private string _play_mode = "NORMAL";

    public DefaultPlayerController (MediaPlayer player, string protocol_info) {
        Object (player : player, protocol_info : protocol_info);
    }

    public override void constructed () {
        base.constructed ();

        this.player.notify["playback-state"].connect (this.notify_state_cb);
        this.player.notify["uri"].connect (this.notify_uri_cb);
        this.player.notify["metadata"].connect (this.notify_metadata_cb);

        this.config = MetaConfig.get_default ();
        this.config.setting_changed.connect (this.on_setting_changed);
        this.default_image_timeout = DEFAULT_IMAGE_TIMEOUT;
        this.on_setting_changed (CONFIG_SECTION, TIMEOUT_KEY);
    }

    public bool next () {
        // Try advancing in playlist
        if (this.track < this.n_tracks) {
            this.track++;

            return true;
        }

        // Try playing next_uri
        if (this.next_uri != "") {
            if (this.next_collection != null) {
                this.set_playlist_uri (this.next_uri,
                                       this.next_metadata,
                                       this.next_collection);
            } else {
                this.set_single_play_uri (this.next_uri,
                                          this.next_metadata,
                                          this.next_mime,
                                          this.next_features);
            }

            this.next_uri = "";
            this.next_metadata = "";
            this.next_mime = null;
            this.next_features = null;
            this.next_collection = null;

            return true;
        }

        return false;
    }

    public bool previous () {
        if (this.track <= 1) {
            return false;
        }

        this.track--;

        return true;
    }

    public void set_single_play_uri (string uri,
                                     string metadata,
                                     string? mime,
                                     string? features)
    {
        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
            this.timeout_id = 0;
        }

        this.metadata = this.unescape (metadata);
        this.uri = uri;

        this.player.mime_type = mime ?? "";
        this.player.content_features = features ?? "*";

        this.track_metadata = this.metadata;
        this.track_uri = this.uri;

        this.playlist = null;

        if (this.uri == "") {
            this.n_tracks = 0;
            this.track = 0;
        } else {
            this.n_tracks = 1;
            this.track = 1;
        }
    }

    public void set_playlist_uri (string uri,
                                  string metadata,
                                  MediaCollection collection) {
        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
            this.timeout_id = 0;
        }

        this.metadata = this.unescape (metadata);
        this.uri = uri;

        this.playlist = collection.get_items ();
        this.n_tracks = this.playlist.length ();

        // bypass track setter: we want to run apply_track()
        // even if track value does not change
        var need_notify = (this.track != 1);
        this._track = 1;
        this.apply_track ();
        if (need_notify) {
            this.notify_property ("track");
        }
    }

    public void set_next_single_play_uri (string uri,
                                          string metadata,
                                          string? mime,
                                          string? features) {
        this.next_uri = uri;
        this.next_metadata = metadata;
        this.next_mime = mime;
        this.next_features = features;
        this.next_collection = null;
    }

    public void set_next_playlist_uri (string uri,
                                       string metadata,
                                       MediaCollection collection) {
        this.next_uri = uri;
        this.next_metadata = metadata;
        this.next_mime = null;
        this.next_features = null;
        this.next_collection = collection;
    }

    private void notify_state_cb (Object player, ParamSpec p) {
        var state = this.player.playback_state;
        if (state == "EOS") {
            // Play next item in playlist, play next_uri, or move to STOPPED
            Idle.add (() => {
                if (!this.next ()) {
                    this.playback_state = "STOPPED";
                }

                return false;
            });
        } else if (this._playback_state != state) {
            // mirror player value in _playback_state and notify
            this._playback_state = state;

            if (this.timeout_id != 0) {
                Source.remove (this.timeout_id);
                this.timeout_id = 0;
            }

            /* start image playlist timeout and update track */
            switch (this._playback_state) {
                case "PLAYING":
                    this.setup_image_timeout ();
                    break;
                case "STOPPED":
                    this.track = 1;
                    break;
                default:
                    break;
            }

            this.notify_property ("playback-state");
        }
    }

    public bool is_play_mode_valid (string play_mode) {
        return play_mode == "NORMAL";
    }

    private void notify_uri_cb (Object player, ParamSpec p) {
        notify_property ("track-uri");
    }

    private void notify_metadata_cb (Object player, ParamSpec p) {
        notify_property ("track-metadata");
    }

    private void apply_track () {
        // We only have something to do here if we have playlist items
        if (this.playlist != null) {
            var item = this.playlist.nth (this.track - 1).data;

            var res = item.get_compat_resource (this.protocol_info, true);
            this.track_metadata = DIDL_FRAME_TEMPLATE.printf
                                        (item.get_xml_string ());
            this.track_uri = res.get_uri ();

            if (this.playback_state == "PLAYING") {
                setup_image_timeout ();
            }
        }
    }

    private void setup_image_timeout () {
        if (this.playlist == null) {
             return;
        }

        var item = this.playlist.nth (this.track - 1).data;
        if (!item.upnp_class.has_prefix ("object.item.image")) {
            return;
        }

        // If image does not have dlna:lifetime tag, then use a default timeout
        var lifetime = item.lifetime;
        if (lifetime <= 0) {
            lifetime = this.default_image_timeout;
        }
        debug ("Item is image, setup timer: %ld", lifetime);

        this.timeout_id = Timeout.add_seconds ((uint) lifetime, () => {
            this.timeout_id = 0;
            if (!this.next ()) {
                this.playback_state = "STOPPED";
            }

            return false;
        });
    }

    private void on_setting_changed (string section, string key) {
        if (section != CONFIG_SECTION && key != TIMEOUT_KEY) {
            return;
        }

        try {
            this.default_image_timeout = config.get_int (CONFIG_SECTION,
                                                         TIMEOUT_KEY,
                                                         0,
                                                         int.MAX);
        } catch (Error error) {
            this.default_image_timeout = DEFAULT_IMAGE_TIMEOUT;
        }

        debug ("New image timeout: %lu", this.default_image_timeout);
    }
}
