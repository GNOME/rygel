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

using Rygel.MPRIS;
using Rygel.MPRIS.MediaPlayer;
using FreeDesktop;

public class Rygel.MPRIS.Player : GLib.Object, Rygel.MediaPlayer {
    private string[] protocols;
    private string[] mime_types;

    private PlayerProxy actual_player;
    private Properties properties;

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
                dur = (int64) val * 1000;
            }

            return dur;
        }
    }

    public int64 position {
        get {
            return this.actual_player.position * 1000;
        }
    }

    public Player (PlayerProxy actual_player,
                   Properties  properties,
                   string[]    mime_types,
                   string[]    protocols) {
        this.actual_player = actual_player;
        this.properties = properties;
        this.mime_types = mime_types;
        this.protocols = protocols;

        this.properties.properties_changed.connect (this.on_properties_changed);
    }

    public bool seek (Gst.ClockTime time) {
        var ret = false;

        try {
            this.actual_player.seek (time / 1000);
            ret = true;
        } catch (Error error) {}

        return ret;
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

    private void on_properties_changed (string                   iface,
                                        HashTable<string,Value?> changed,
                                        string[]                 invalidated) {
        if (changed.lookup ("PlaybackStatus") != null) {
            this.notify_property ("playback-state");
        }

        if (changed.lookup ("Volume") != null) {
            this.notify_property ("volume");
        }

        if (changed.lookup ("Metadata") != null) {
            var metadata = this.actual_player.metadata;

            if (metadata.lookup ("xesam:url") != null) {
                this.notify_property ("uri");
            }

            if (metadata.lookup ("mpris:length") != null) {
                this.notify_property ("duration");
            }
        }
    }
}
