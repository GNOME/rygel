/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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
internal class Rygel.PlayerController : Object {
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
        private set {
            if (value != this._n_tracks) {
                this._n_tracks = value;
                this.notify_property ("n-tracks");
            }
        }
        default = 0;
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
        default = 0;
    }

    public string uri { get; private set; default = ""; }
    public string metadata { get; private set; default = ""; }

    [CCode (notify = false)]
    public string track_uri {
        owned get {
            if (this.player.uri != null) {
                return Markup.escape_text (this.player.uri);
            } else {
                return "";
            }
        }

        private set {
            this.player.uri = value;
        }
    }

    [CCode (notify = false)]
    public string track_metadata {
        owned get { return this.player.metadata ?? ""; }

        private set {
            if (value.has_prefix ("&lt;")) {
                this.player.metadata = this.unescape (value);
            } else {
                this.player.metadata = value;
            }
        }
    }

    public string next_uri { get; private set; default = ""; }
    public string next_metadata { get; private set; default = ""; }

    public string current_transport_actions {
        owned get {
            string actions = null;
            switch (this.playback_state) {
                case "PLAYING":
                case "TRANSITIONING":
                    actions = "Stop,Seek,Pause";
                    break;
                case "STOPPED":
                    actions = "Play";
                    break;
                case "PAUSED_PLAYBACK":
                    actions = "Stop,Play,Seek";
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
                actions += ",X_DLNA_SeekTime";
            }
            if (actions != null && this.player.can_seek_bytes) {
                actions += ",X_DLNA_SeekByte";
            }

            if (actions != null &&
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

    // Private members
    private List<DIDLLiteItem> playlist;
    private uint timeout_id;
    private uint default_image_timeout;
    private Configuration config;

    private string next_features;
    private string next_mime;
    private MediaCollection next_collection;

    // Private property variables
    private uint _n_tracks;
    private uint _track;
    private string _playback_state = "NO_MEDIA_PRESENT";

    public PlayerController (MediaPlayer player, string protocol_info) {
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
            this.timeout_id = 0;
            Source.remove (this.timeout_id);
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
            this.timeout_id = 0;
            Source.remove (this.timeout_id);
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
                    this.reset ();
                }

                return false;
            });
        } else if (this._playback_state != state) {
            // mirror player value in _playback_state and notify
            this._playback_state = state;
            this.notify_property ("playback-state");
        }
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

            if (item.upnp_class.has_prefix ("object.item.image") &&
                this.playback_state != "STOPPED") {
                this.setup_image_timeouts (item.lifetime);
            }
        }
    }

    private void reset () {
        this.playback_state = "STOPPED";
        this.track = 1;
    }

    private void setup_image_timeouts (long lifetime) {
        // For images, we handle the timeout here. Either the item carries a
        // dlna:lifetime tag, then we use that or we use a default timeout of
        // 5 minutes.
        var timeout = this.default_image_timeout;
        if (lifetime > 0) {
            timeout = (uint) lifetime;
        }

        debug ("Item is image, setup timer: %ld", timeout);

        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
        }

        this.timeout_id = Timeout.add_seconds ((uint) timeout, () => {
            this.timeout_id = 0;
            if (!this.next ()) {
                this.reset ();
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

    private string unescape (string input) {
        var result = input.replace ("&quot;", "\"");
        result = result.replace ("&lt;", "<");
        result = result.replace ("&gt;", ">");
        result = result.replace ("&apos;", "'");
        result = result.replace ("&amp;", "&");

        return result;
    }
}
