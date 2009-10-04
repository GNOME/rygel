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

using Gtk;
using Gst;
using Owl;

public class Rygel.GstVideoWindow : Window {
    private static GstVideoWindow video_window;

    private VideoWidget video_widget;

    private string _playback_state = "STOPPED";
    public string playback_state {
        get {
            return this._playback_state;
        }

        set {
            this._playback_state = value;

            switch (_playback_state) {
                case "STOPPED":
                    this.video_widget.playing = false;

                if (this.video_widget.can_seek) {
                    this.video_widget.position = 0;
                }

                break;
                case "PAUSED_PLAYBACK":
                    this.video_widget.playing = false;
                break;
                case "PLAYING":
                    this.video_widget.playing = true;
                break;
                default:
                break;
            }
        }
    }

    public string uri {
        get {
            return this.video_widget.uri;
        }

        set {
            this.video_widget.uri = value;
        }
    }

    public double volume {
        get {
            return this.video_widget.volume;
        }

        set {
            this.video_widget.volume = value;
        }
    }

    public string duration { get; private set; }
    public string playback_position { get; private set; }

    private GstVideoWindow () {
        this.fullscreen_state = true;

        // Show a video widget
        this.video_widget = new VideoWidget ();

        this.video_widget.notify["duration"] += this.notify_duration_cb;
        this.video_widget.notify["position"] += this.notify_position_cb;
        this.video_widget.eos += this.eos_cb;

        this.add (this.video_widget);
        this.show_all ();

        this.key_press_event += this.key_press_callback;
    }

    public static GstVideoWindow get_default () {
        if (video_window == null) {
            var args = new string[0];
            Gtk.init (ref args);

            video_window = new GstVideoWindow ();
        }

        return video_window;
    }

    public bool fullscreen_state {
        get {
            if (this.window != null) {
                return (this.window.get_state () &
                        Gdk.WindowState.FULLSCREEN) != 0;
            }

            return false;
        }

        set {
            if (value)
                this.fullscreen ();
            else {
                this.unfullscreen ();
            }
        }
    }

    private bool key_press_callback (GstVideoWindow window,
                                     Gdk.EventKey   event) {
        switch (event.keyval) {
            case 0xffc8: /* Gdk.KeySyms.F11 */
                this.fullscreen_state = ! fullscreen_state;
                break;
            case 0xff1b: /* Gdk.KeySyms.Escape */
                this.fullscreen_state = false;
                break;
            default:
                break;
        }
        return false;
    }

    private void eos_cb (VideoWidget video_widget) {
        this.playback_state = "STOPPED";
    }

    private void notify_duration_cb (VideoWidget video_widget,
                                     ParamSpec   p) {
        this.duration = Time.to_string (video_widget.duration);
    }

    private void notify_position_cb (VideoWidget video_widget,
                                     ParamSpec   p) {
        this.playback_position = Time.to_string (video_widget.position);
    }

    public bool seek (string time) {
        if (this.video_widget.can_seek) {
            this.video_widget.position = Time.from_string (time);

            return true;
        } else {
            return false;
        }
    }
}

// Helper class for converting between second and string representations
// of time.
private class Time {
    public static int from_string (string str) {
        int hours, minutes, seconds;

        str.scanf ("%d:%2d:%2d%*s", out hours, out minutes, out seconds);

        return hours * 3600 + minutes * 60 + seconds;
    }

    public static string to_string (int time) {
        int hours, minutes, seconds;

        hours   = time / 3600;
        seconds = time % 3600;
        minutes = seconds / 60;
        seconds = seconds % 60;

        return "%d:%.2d:%.2d".printf (hours, minutes, seconds);
    }
}

