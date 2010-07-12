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

public class Rygel.GstRenderer.Player : GLib.Object {
    private static Player player;

    private dynamic Element playbin;

    private string _playback_state = "STOPPED";
    public string playback_state {
        get {
            return this._playback_state;
        }

        set {
            debug (_("Changing playback state to %s.."), value);
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

    public string uri {
        get {
            return this.playbin.uri;
        }

        set {
            this.playbin.uri = value;
            debug (_("URI set to %s."), value);
        }
    }

    public double volume {
        get {
            return this.playbin.volume;
        }

        set {
            this.playbin.volume = value;
            debug (_("volume set to %f."), value);
        }
    }

    public string duration {
        owned get {
            var format = Format.TIME;
            int64 dur;

            if (this.playbin.query_duration (ref format, out dur)) {
                return Time.to_string ((ClockTime) dur);
            } else {
                return "00:00:00";
            }
        }
    }

    public string position {
        owned get {
            var format = Format.TIME;
            int64 pos;

            if (this.playbin.query_position (ref format, out pos)) {
                return Time.to_string ((ClockTime) pos);
            } else {
                return "00:00:00";
            }
        }
    }

    private Player () {
        this.playbin = ElementFactory.make ("playbin2", null);
        assert (this.playbin != null);

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

    public bool seek (string time) {
        debug (_("Seeking to %s."), time);
        return this.playbin.seek (1.0,
                                  Format.TIME,
                                  SeekFlags.FLUSH,
                                  Gst.SeekType.SET,
                                  Time.from_string (time),
                                  Gst.SeekType.NONE,
                                  -1);
    }

    private bool bus_handler (Gst.Bus bus,
                              Message message) {
        if (message.type == MessageType.EOS) {
            debug ("EOS");
            this.playback_state = "STOPPED";
        }

        return true;
    }
}

// Helper class for converting between Gstreamer time units and string
// representations of time.
private class Rygel.GstRenderer.Time {
    public static ClockTime from_string (string str) {
        uint64 hours, minutes, seconds;

        str.scanf ("%llu:%2llu:%2llu%*s", out hours, out minutes, out seconds);

        return (ClockTime) ((hours * 3600 + minutes * 60 + seconds) *
                            Gst.SECOND);
    }

    public static string to_string (ClockTime time) {
        uint64 hours, minutes, seconds;

        hours   = time / Gst.SECOND / 3600;
        seconds = time / Gst.SECOND % 3600;
        minutes = seconds / 60;
        seconds = seconds % 60;

        return "%llu:%.2llu:%.2llu".printf (hours, minutes, seconds);
    }
}

