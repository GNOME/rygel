/*
 * Copyright (C) 2008 OpenedHand Ltd.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
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

public class Rygel.GstVideoWindow : GLib.Object {
    private static GstVideoWindow video_window;

    private dynamic Element playbin;

    private string _playback_state = "STOPPED";
    public string playback_state {
        get {
            return this._playback_state;
        }

        set {
            this._playback_state = value;

            switch (_playback_state) {
                case "STOPPED":
                    this.playbin.set_state (State.NULL);
                break;
                case "PAUSED_PLAYBACK":
                    this.playbin.set_state (State.PLAYING);
                break;
                case "PLAYING":
                    this.playbin.set_state (State.PAUSED);
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
        }
    }

    public double volume {
        get {
            return this.playbin.volume;
        }

        set {
            this.playbin.volume = value;
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

    private GstVideoWindow () {
        this.playbin = ElementFactory.make ("playbin2", null);
        assert (this.playbin != null);

        this.playbin.eos += this.eos_cb;
    }

    public static GstVideoWindow get_default () {
        if (video_window == null) {
            video_window = new GstVideoWindow ();
        }

        return video_window;
    }

    private void eos_cb (Element playbin) {
        this.playback_state = "STOPPED";
    }

    public bool seek (string time) {
        return this.playbin.seek (1.0,
                                  Format.TIME,
                                  SeekFlags.FLUSH,
                                  Gst.SeekType.SET,
                                  Time.from_string (time),
                                  Gst.SeekType.NONE,
                                  -1);
    }
}

// Helper class for converting between Gstreamer time units and string
// representations of time.
private class Time {
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

