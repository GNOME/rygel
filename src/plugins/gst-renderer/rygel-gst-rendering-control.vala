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

using GUPnP;
using Rygel;

public class Rygel.GstRenderingControl : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:RenderingControl";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:RenderingControl:2";
    public const string DESCRIPTION_PATH = "xml/RenderingControl2.xml";
    public const string LAST_CHANGE_NS =
                    "urn:schemas-upnp-org:metadata-1-0/RCS/";

    private bool _mute = false;
    public bool mute {
        get {
            return _mute;
        }

        set {
            _mute = value;

            if (this._mute) {
                this.video_window.volume = 0;
            } else {
                this.video_window.volume = Volume.from_percentage (this.volume);
            }

            this.changelog.log_with_channel ("Mute",
                                             this.mute ? "1" : "0",
                                             "Master");
        }
    }

    private uint _volume = 0;
    public uint volume {
        get {
            return _volume;
        }

        set {
            _volume = value;

            if (!this.mute) {
                this.video_window.volume = Volume.from_percentage (this.volume);
            }

            this.changelog.log_with_channel ("Volume",
                                             this.volume.to_string (),
                                             "Master");
        }
    }

    private string preset_name_list = "";

    private GstChangeLog changelog;
    private GstVideoWindow video_window;

    public override void constructed () {
        this.changelog = new GstChangeLog (this, LAST_CHANGE_NS);
        this.video_window = GstVideoWindow.get_default ();

        query_variable["LastChange"] += query_last_change_cb;

        action_invoked["ListPresets"]  += list_presets_cb;
        action_invoked["SelectPreset"] += select_preset_cb;
        action_invoked["GetMute"]      += get_mute_cb;
        action_invoked["SetMute"]      += set_mute_cb;
        action_invoked["GetVolume"]    += get_volume_cb;
        action_invoked["SetVolume"]    += set_volume_cb;

        this._volume = Volume.to_percentage (this.video_window.volume);
    }

    private void query_last_change_cb (GstRenderingControl s,
                                       string              variable,
                                       ref GLib.Value      value) {
        // Send current state
        var log = new GstChangeLog (null, LAST_CHANGE_NS);

        log.log_with_channel ("Mute", mute ? "1" : "0", "Master");
        log.log_with_channel ("Volume", this.volume.to_string (), "Master");

        value.init (typeof (string));
        value.set_string (log.finish ());
    }

    // Error out if InstanceID is not 0
    private bool check_instance_id (ServiceAction action) {
        uint instance_id;

        action.get ("InstanceID", typeof (uint), out instance_id);
        if (instance_id != 0) {
            action.return_error (702, "Invalid InstanceID");

            return false;
        }

        return true;
    }

    private void list_presets_cb (GstRenderingControl s,
                                  owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        action.set ("CurrentPresetNameList",
                        typeof (string),
                        this.preset_name_list);

        action.return ();
    }

    private void select_preset_cb (GstRenderingControl s,
                                   owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        string preset_name;

        action.get ("PresetName", typeof (string), out preset_name);
        if (preset_name != "") {
            action.return_error (701, "Invalid Name");

            return;
        }

        action.return ();
    }

    // Error out if 'Channel' is not 'Master'
    private bool check_channel (ServiceAction action) {
        string channel;

        action.get ("Channel", typeof (string), out channel);
        if (channel != "Master") {
            action.return_error (501, "Action Failed");

            return false;
        }

        return true;
    }

    private void get_mute_cb (GstRenderingControl s,
                              owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        action.set ("CurrentMute", typeof (bool), this.mute);

        action.return ();
    }

    private void set_mute_cb (GstRenderingControl s,
                              owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        bool mute;

        action.get ("DesiredMute", typeof (bool), out mute);

        this.mute = mute;

        action.return ();
    }

    private void get_volume_cb (GstRenderingControl s,
                                owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        action.set ("CurrentVolume", typeof (uint), this.volume);

        action.return ();
    }

    private void set_volume_cb (GstRenderingControl s,
                                owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        uint volume;

        action.get ("DesiredVolume", typeof (uint), out volume);
        if (volume > 100) {
            action.return_error (501, "Action Failed");

            return;
        }

        this.volume = volume;

        action.return ();
    }
}

// Helper class for converting between double and percentage representations
// of volume.
private class Volume {
    public static double from_percentage (uint percentage) {
        return (double) percentage / 100.0;
    }

    public static uint to_percentage (double volume) {
        return (uint) (volume * 100.0);
    }
}

