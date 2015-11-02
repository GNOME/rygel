/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 * Copyright (C) 2015 Jens Georg
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Sivakumar Mani <siva@orexel.com>
 *         Jens Georg <mail@jensge.org>
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

using Rygel.MPRIS;
using Rygel.MPRIS.MediaPlayer;
using FreeDesktop;

public class Rygel.MPRIS.Player : GLib.Object, Rygel.MediaPlayer {
    private string[] protocols;
    private string[] mime_types;

    private PlayerProxy actual_player;

    public string? user_agent { owned get; set; }

    public string playback_state {
        owned get {
            return this.mpris_to_upnp_state (actual_player.playback_status);
        }

        set {
            debug ("Changing playback state to %s..", value);

            /* FIXME: Do something about errors below */
            switch (value) {
            case "STOPPED":
                try {
                    this.actual_player.stop ();
                } catch (Error error) {}

                break;
            case "PAUSED_PLAYBACK":
                try {
                    this.actual_player.pause ();
                } catch (Error error) {}

                break;
            case "PLAYING":
                try {
                    this.actual_player.play ();
                } catch (Error error) {}

                break;
            default:
                assert_not_reached ();
            }
        }
    }

    private string[] _allowed_playback_speeds = {"1"};
    public string[] allowed_playback_speeds {
        owned get {
            return this._allowed_playback_speeds;
        }
    }

    private string _playback_speed = "1";
    public string playback_speed {
        owned get {
            return this._playback_speed;
        }

        set {
            this.actual_player.rate = this.play_speed_to_double (value);
            this._playback_speed = value;
        }
    }

    public double minimum_rate {
        get {
            return this.play_speed_to_double (_allowed_playback_speeds[0]);
        }
    }

    public double maximum_rate {
        get {
            int i = _allowed_playback_speeds.length;

            assert (i > 0);

            return this.play_speed_to_double (_allowed_playback_speeds[i-1]);
        }
    }

    public string? uri {
        owned get {
            var val = this.actual_player.metadata.lookup ("xesam:url");

            if (val != null) {
                return (string) val;
            } else {
                return null;
            }
        }

        set {
            try {
                this.actual_player.open_uri (value);
            } catch (Error error) {}
        }
    }

    public string? mime_type { owned get; set; }
    public string? metadata { owned get; set; }
    public string? content_features { owned get; set; }

    public bool can_seek {
        get {
            return this.actual_player.can_seek;
        }
    }

    public bool can_seek_bytes {
        get {
            return false;
        }
    }

    public double volume {
        get {
            return this.actual_player.volume;
        }

        set {
            this.actual_player.volume = value;
        }
    }

    public int64 duration {
        get {
            var val = this.actual_player.metadata.lookup ("mpris:length");
            int64 dur = 0;

            if (val != null) {
                dur = (int64) val;
            }

            return dur;
        }
    }

    public int64 size {
        get {
            return 0;
        }
    }

    public int64 position {
        get {
            // Remove cached value. Position is not supposed to be notified
            // so the cache might be outdated.
            this.actual_player.set_cached_property ("Position", null);

            return this.actual_player.position;
        }
    }

    public int64 byte_position {
        get {
            return 0;
        }
    }


    public Player (Plugin plugin) {
        this.actual_player = plugin.actual_player;
        this.mime_types = plugin.mime_types;
        this.protocols = plugin.protocols;

        actual_player.g_properties_changed.connect (this.on_properties_changed);
    }

    public override void constructed () {
        base.constructed ();

        // force synchronisation of current state
        Idle.add (() => {
            this.notify_property ("playback-state");
            this.notify_property ("volume");
            this.notify_property ("uri");
            this.notify_property ("duration");

            return false;
        });
    }

    public bool seek (int64 time) {
        var ret = false;

        try {
            this.actual_player.seek (time - this.position);
            ret = true;
        } catch (Error error) {}

        return ret;
    }

    public bool seek_bytes (int64 bytes) {
        return false;
    }

    public string[] get_protocols () {
        return this.protocols;
    }

    public string[] get_mime_types () {
        return this.mime_types;
    }

    private string mpris_to_upnp_state (string state) {
        switch (state) {
        case "Stopped":
            return "STOPPED";
        case "Paused":
            return "PAUSED_PLAYBACK";
        case "Playing":
            return "PLAYING";
        default:
            assert_not_reached ();
        }
    }

    private void on_properties_changed (DBusProxy actual_player,
                                        Variant   changed,
                                        string[]  invalidated) {
        if (!changed.get_type().equal (VariantType.VARDICT)) {
            return;
        }

        foreach (var changed_prop in changed) {
            var key = (string) changed_prop.get_child_value (0);
            var value = changed_prop.get_child_value (1).get_child_value (0);

            switch (key) {
            case "PlaybackStatus":
                this.notify_property ("playback-state");

                break;
            case "Volume":
                this.notify_property ("volume");

                break;
            case "Metadata":
                this.on_properties_changed (actual_player,
                                            value,
                                            new string[0]);

                break;
            case "xesam:url":
                this.notify_property ("uri");

                break;
            case "mpris:length":
                this.notify_property ("duration");

                break;
            }
        }
    }
}
