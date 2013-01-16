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
    [CCode (notify = false)]
    public string playback_state {
        get { return this._playback_state; }
        set {
            if (this._playback_state != value) {
                this._playback_state = value;
                this.notify_property ("playback-state");
            }
        }
        default = "NO_MEDIA_PRESENT";
    }
    public uint n_tracks { get; set; default = 0; }
    public uint track {
        get { return this._track; }
        set { this._track = value; this.apply_track (); }
        default = 0;
    }
    public string uri { get; set; default = ""; }
    public string metadata {
        owned get { return this._metadata ?? ""; }
        set { this._metadata = this.unescape (value); }
        default = "";
    }

    public string current_transport_actions {
        owned get {
            string actions = null;
            switch (this._playback_state) {
                case "PLAYING":
                case "TRANSITIONING":
                    actions = "Stop,Seek,Pause";
                    break;
                case "STOPPED":
                case "PAUSED_PLAYBACK":
                    actions = "Play,Seek";
                    break;
                default:
                    break;
            }
            if (actions != null && this.player.can_seek) {
                actions += ",X_DLNA_SeekTime";

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

            if (actions == null) {
                return "";
            }

            return actions;
        }
    }

    // Private members
    private MediaCollection collection;
    private List<DIDLLiteItem> collection_items;
    private uint timeout_id;
    private uint default_image_timeout;
    private Configuration config;

    // Private property variables
    private string _metadata;
    private uint _track;
    private string _playback_state;

    public PlayerController (MediaPlayer player, string protocol_info) {
        Object (player : player, protocol_info : protocol_info);
    }

    public override void constructed () {
        base.constructed ();

        this.player.notify["playback-state"].connect (this.notify_state_cb);

        this.config = MetaConfig.get_default ();
        this.config.setting_changed.connect (this.on_setting_changed);
        this.default_image_timeout = DEFAULT_IMAGE_TIMEOUT;
        this.on_setting_changed (CONFIG_SECTION, TIMEOUT_KEY);
    }

    public bool next () {
        if (this.track + 1 > this.n_tracks) {
            return false;
        }

        this.track++;

        return true;
    }

    public bool previous () {
        if (this.track <= 1) {
            return false;
        }

        this.track--;

        return true;
    }

    public void set_playlist (MediaCollection? collection) {
        this.collection = collection;
        if (this.timeout_id != 0) {
            this.timeout_id = 0;
            Source.remove (this.timeout_id);
        }

        if (this.collection != null) {
            this.collection_items = collection.get_items ();
            this.n_tracks = this.collection_items.length ();
            this.track = 1;
        } else {
            this.collection_items = null;
        }
    }

    private void notify_state_cb (Object player, ParamSpec p) {
        var state = this.player.playback_state;
        if (state == "EOS") {
            if (this.collection == null) {
                // Just move to stop
                Idle.add (() => {
                    this.player.playback_state = "STOPPED";

                    return false;
                });

                return;
            } else {
                // Set next playlist item
                if (!this.next ()) {
                    // We were at the end of the list; as per DLNA, move to
                    // STOPPED and let current track be 1.
                    this.reset ();
                }
            }
        } else {
            // just forward
            this.playback_state = state;
        }
    }

    private void apply_track () {
        // We only have something to do here if we have collection items
        if (this.collection_items != null) {
            var item = this.collection_items.nth (this.track - 1).data;

            var res = item.get_compat_resource (this.protocol_info, true);
            this.player.metadata = DIDL_FRAME_TEMPLATE.printf
                                        (item.get_xml_string ());
            this.player.uri = res.get_uri ();
            if (item.upnp_class.has_prefix ("object.item.image") &&
                this.collection != null) {
                this.setup_image_timeouts (item.lifetime);
            }
        }
    }

    private void reset () {
        this.player.playback_state = "STOPPED";
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
