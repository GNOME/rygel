/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Rygel;

internal class Rygel.RenderingControl : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:RenderingControl";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:RenderingControl:2";
    public const string DESCRIPTION_PATH = "xml/RenderingControl2.xml";
    public const string LAST_CHANGE_NS =
                    "urn:schemas-upnp-org:metadata-1-0/RCS/";

    private bool _mute = false;
    public bool mute {
        get {
            return this._mute;
        }

        set {
            this._mute = value;

            if (this._mute) {
                this.player.volume = 0;
            } else {
                this.player.volume = Volume.from_percentage (this.volume);
            }

            this.changelog.log_with_channel ("Mute",
                                             this.mute ? "1" : "0",
                                             "Master");
        }
    }

    private uint _volume = 0;
    public uint volume {
        get {
            return this._volume;
        }

        set {
            this._volume = value;

            if (!this.mute) {
                this.player.volume = Volume.from_percentage (this.volume);
            }

            this.changelog.log_with_channel ("Volume",
                                             this.volume.to_string (),
                                             "Master");
        }
    }

    private string preset_name_list = "FactoryDefaults";

    private ChangeLog changelog;
    private MediaPlayer player;

    public override void constructed () {
        base.constructed ();

        this.changelog = new ChangeLog (this, LAST_CHANGE_NS);
        this.player = this.get_player ();

        query_variable["LastChange"].connect (this.query_last_change_cb);

        action_invoked["ListPresets"].connect (this.list_presets_cb);
        action_invoked["SelectPreset"].connect (this.select_preset_cb);
        action_invoked["GetMute"].connect (this.get_mute_cb);
        action_invoked["SetMute"].connect (this.set_mute_cb);
        action_invoked["GetVolume"].connect (this.get_volume_cb);
        action_invoked["SetVolume"].connect (this.set_volume_cb);

        this.player.notify["volume"].connect (this.notify_volume_cb);

        this._mute = this.player.volume == 0;
        this._volume = Volume.to_percentage (this.player.volume);
    }

    private void query_last_change_cb (Service        service,
                                       string         variable,
                                       ref GLib.Value value) {
        // Send current state
        var log = new ChangeLog (null, LAST_CHANGE_NS);

        log.log_with_channel ("Mute", this.mute ? "1" : "0", "Master");
        log.log_with_channel ("Volume", this.volume.to_string (), "Master");
        log.log_with_channel ("PresetNameList",
                              this.preset_name_list,
                              "Master");

        value.init (typeof (string));
        value.set_string (log.finish ());
    }

    private MediaPlayer get_player () {
        var plugin = this.root_device.resource_factory as MediaRendererPlugin;

        return plugin.get_player ();
    }

    // Error out if InstanceID is not 0
    private bool check_instance_id (ServiceAction action) {
        string instance_id_string;
        int64 instance_id = -1;

        action.get ("InstanceID", typeof (string), out instance_id_string);
        if (instance_id_string == null ||
            !int64.try_parse (instance_id_string, out instance_id)) {
            action.return_error (402, _("Invalid argument"));

            return false;
        }

        if (instance_id != 0) {
            action.return_error (702, _("Invalid InstanceID"));

            return false;
        }

        return true;
    }

    private void list_presets_cb (Service       service,
                                  ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("CurrentPresetNameList",
                        typeof (string),
                        this.preset_name_list);

        action.return_success ();
    }

    private void select_preset_cb (Service       service,
                                   ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string preset_name;

        action.get ("PresetName", typeof (string), out preset_name);
        if (preset_name != "") {
            action.return_error (701, _("Invalid Name"));

            return;
        }

        action.return_success ();
    }

    // Error out if 'Channel' is not 'Master'
    private bool check_channel (ServiceAction action) {
        string channel;

        action.get ("Channel", typeof (string), out channel);
        if (channel != "Master") {
            action.return_error (703, _("Invalid Channel"));

            return false;
        }

        return true;
    }

    private void get_mute_cb (Service       service,
                              ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        action.set ("CurrentMute", typeof (bool), this.mute);

        action.return_success ();
    }

    private void set_mute_cb (Service       service,
                              ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        string mute_str;
        action.get ("DesiredMute", typeof (string), out mute_str);
        if (mute_str.has_prefix ("-")) {
            action.return_error (501, _("Action Failed"));

            return;
        }

        bool mute;

        action.get ("DesiredMute", typeof (bool), out mute);

        this.mute = mute;

        action.return_success ();
    }

    private void get_volume_cb (Service       service,
                                ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        action.set ("CurrentVolume", typeof (uint), this.volume);

        action.return_success ();
    }

    private void set_volume_cb (Service       service,
                                ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (!check_channel (action)) {
            return;
        }

        string volume_str;
        action.get ("DesiredVolume", typeof (string), out volume_str);
        if ("." in volume_str || "," in volume_str) {
            action.return_error (501, _("Action Failed"));

            return;
        }

        uint volume;

        action.get ("DesiredVolume", typeof (uint), out volume);
        if (volume > 100) {
            action.return_error (501, _("Action Failed"));

            return;
        }

        this.volume = volume;

        action.return_success ();
    }

    private void notify_volume_cb (Object player, ParamSpec p) {
        this._volume = Volume.to_percentage (this.player.volume);

        if (this._mute && this.player.volume > 0) {
            // We are not muted anymore...
            this._mute = false;
            this.changelog.log_with_channel ("Mute",
                                             "0",
                                             "Master");
        }

        this.changelog.log_with_channel ("Volume",
                                         this.volume.to_string (),
                                         "Master");
    }
}
