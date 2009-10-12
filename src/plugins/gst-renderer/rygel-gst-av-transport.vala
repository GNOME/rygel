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

public class Rygel.GstAVTransport : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:AVTransport";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:AVTransport:2";
    public const string DESCRIPTION_PATH = "xml/AVTransport2.xml";

    // The setters below update the LastChange message
    private uint _n_tracks = 0;
    public uint n_tracks {
        get {
            return _n_tracks;
        }

        set {
            _n_tracks = value;

            this.changelog.log ("NumberOfTracks", _n_tracks.to_string ());
        }
    }

    private uint _track = 0;
    public uint track {
        get {
            return _track;
        }

        set {
            _track = value;

            this.changelog.log ("CurrentTrack", _track.to_string ());
        }
    }

    private string _metadata = "";
    public string metadata {
        owned get {
            if (this._metadata != null) {
                return Markup.escape_text (this._metadata);
            } else {
                return "";
            }
        }

        set {
            _metadata = value;

            this.changelog.log ("CurrentTrackMetadata", this.metadata);
        }
    }

    public string uri {
        owned get {
            if (this.video_window.uri != null) {
                return Markup.escape_text (this.video_window.uri);
            } else {
                return "";
            }
        }

        set {
            this.video_window.uri = value;

            this.changelog.log ("CurrentTrackURI", this.uri);
            this.changelog.log ("AVTransportURI", this.uri);
        }
    }

    private string _status = "OK";
    public string status {
        get {
            return _status;
        }

        set {
            _status = value;

            this.changelog.log ("TransportStatus", _status);
        }
    }

    private string _speed = "1";
    public string speed {
        get {
            return _speed;
        }

        set {
            _speed = value;

            this.changelog.log ("TransportPlaySpeed", _speed);
        }
    }

    private string _mode = "NORMAL";
    public string mode {
        get {
            return _mode;
        }

        set {
            _mode = value;

            this.changelog.log ("CurrentPlayMode", _mode);
        }
    }

    private GstChangeLog changelog;
    private GstVideoWindow video_window;

    public override void constructed () {
        this.changelog = new GstChangeLog (this);
        this.video_window = GstVideoWindow.get_default ();

        query_variable["LastChange"] += query_last_change_cb;

        action_invoked["SetAVTransportURI"]     += set_av_transport_uri_cb;
        action_invoked["GetMediaInfo"]          += get_media_info_cb;
        action_invoked["GetTransportInfo"]      += get_transport_info_cb;
        action_invoked["GetPositionInfo"]       += get_position_info_cb;
        action_invoked["GetDeviceCapabilities"] += get_device_capabilities_cb;
        action_invoked["GetTransportSettings"]  += get_transport_settings_cb;
        action_invoked["Stop"]                  += stop_cb;
        action_invoked["Play"]                  += play_cb;
        action_invoked["Pause"]                 += pause_cb;
        action_invoked["Seek"]                  += seek_cb;
        action_invoked["Next"]                  += next_cb;
        action_invoked["Previous"]              += previous_cb;

        this.video_window.notify["playback-state"] += this.notify_state_cb;
        this.video_window.notify["duration"] += this.notify_duration_cb;
    }

    private void query_last_change_cb (GstAVTransport s,
                                       string         variable,
                                       ref Value      value) {
        // Send current state
        GstChangeLog log = new GstChangeLog (null);

        log.log ("TransportState",
                 this.video_window.playback_state);
        log.log ("TransportStatus",              this.status);
        log.log ("PlaybackStorageMedium",        "NOT_IMPLEMENTED");
        log.log ("RecordStorageMedium",          "NOT_IMPLEMENTED");
        log.log ("PossiblePlaybackStorageMedia", "NOT_IMPLEMENTED");
        log.log ("PossibleRecordStorageMedia",   "NOT_IMPLEMENTED");
        log.log ("CurrentPlayMode",              this.mode);
        log.log ("TransportPlaySpeed",           this.speed);
        log.log ("RecordMediumWriteStatus",      "NOT_IMPLEMENTED");
        log.log ("CurrentRecordQualityMode",     "NOT_IMPLEMENTED");
        log.log ("PossibleRecordQualityMode",    "NOT_IMPLEMENTED");
        log.log ("NumberOfTracks",               this.n_tracks.to_string ());
        log.log ("CurrentTrack",                 this.track.to_string ());
        log.log ("CurrentTrackDuration",         this.video_window.duration);
        log.log ("CurrentMediaDuration",         this.video_window.duration);
        log.log ("CurrentTrackMetadata",         this.metadata);
        log.log ("CurrentTrackURI",              this.uri);
        log.log ("AVTransportURI",               this.uri);
        log.log ("NextAVTransportURI",           "NOT_IMPLEMENTED");

        value.init (typeof (string));
        value.set_string (log.finish ());
    }

    // Error out if InstanceID is not 0
    private bool check_instance_id (ServiceAction action) {
        uint instance_id;

        action.get ("InstanceID", typeof (uint), out instance_id);
        if (instance_id != 0) {
            action.return_error (718, "Invalid InstanceID");

            return false;
        }

        return true;
    }

    private void set_av_transport_uri_cb (GstAVTransport      s,
                                          owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        string _uri, _metadata;

        action.get ("CurrentURI",         typeof (string), out _uri,
                    "CurrentURIMetaData", typeof (string), out _metadata);

        this.uri = _uri;
        this.metadata = _metadata;

        action.return ();
    }

    private void get_media_info_cb (GstAVTransport      s,
                                    owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }


        action.set ("NrTracks",
                        typeof (uint),
                        this.n_tracks,
                    "MediaDuration",
                        typeof (string),
                        this.video_window.duration,
                    "CurrentURI",
                        typeof (string),
                        this.uri,
                    "CurrentURIMetaData",
                        typeof (string),
                        this.metadata,
                    "NextURI",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "NextURIMetaData",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "PlayMedium",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "RecordMedium",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "WriteStatus",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return ();
    }

    private void get_transport_info_cb (GstAVTransport      s,
                                        owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        action.set ("CurrentTransportState",
                        typeof (string),
                        this.video_window.playback_state,
                    "CurrentTransportStatus",
                        typeof (string),
                        this.status,
                    "CurrentSpeed",
                        typeof (string),
                        this.speed);

        action.return ();
    }

    private void get_position_info_cb (GstAVTransport      s,
                                       owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        action.set ("Track",
                        typeof (uint),
                        this.track,
                    "TrackDuration",
                        typeof (string),
                        this.video_window.duration,
                    "TrackMetaData",
                        typeof (string),
                        this.metadata,
                    "TrackURI",
                        typeof (string),
                        this.uri,
                    "RelTime",
                        typeof (string),
                        this.video_window.position,
                    "AbsTime",
                        typeof (string),
                        this.video_window.position,
                    "RelCount",
                        typeof (int),
                        int.MAX,
                    "AbsCount",
                        typeof (int),
                        int.MAX);

        action.return ();
    }

    private void get_device_capabilities_cb (GstAVTransport      s,
                                             owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        action.set ("PlayMedia",       typeof (string), "NOT_IMPLEMENTED",
                    "RecMedia",        typeof (string), "NOT_IMPLEMENTED",
                    "RecQualityModes", typeof (string), "NOT_IMPLEMENTED");

        action.return ();
    }

    private void get_transport_settings_cb (GstAVTransport      s,
                                            owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        action.set ("PlayMode",       typeof (string), this.mode,
                    "RecQualityMode", typeof (string), "NOT_IMPLEMENTED");

        action.return ();
    }

    private void stop_cb (GstAVTransport s, owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        this.video_window.playback_state = "STOPPED";

        action.return ();
    }

    private void play_cb (GstAVTransport s, owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        string speed;

        action.get ("Speed", typeof (string), out speed);
        if (speed != "1") {
            action.return_error (717, "Play speed not supported");

            return;
        }

        this.video_window.playback_state = "PLAYING";

        action.return ();
    }

    private void pause_cb (GstAVTransport s, owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        this.video_window.playback_state = "PAUSED_PLAYBACK";

        action.return ();
    }

    private void seek_cb (GstAVTransport s, owned ServiceAction action) {
        if (!check_instance_id (action)) {
            return;
        }

        string unit, target;

        action.get ("Unit",   typeof (string), out unit,
                    "Target", typeof (string), out target);
        switch (unit) {
        case "ABS_TIME":
        case "REL_TIME":
            if (!this.video_window.seek (target)) {
                action.return_error (710, "Seek mode not supported");

                return;
            }

            action.return ();

            return;
        default:
            action.return_error (710, "Seek mode not supported");

            return;
        }
    }

    private void next_cb (GstAVTransport s, owned ServiceAction action) {
        action.return_error (701, "Transition not available");
    }

    private void previous_cb (GstAVTransport s, owned ServiceAction action) {
        action.return_error (701, "Transition not available");
    }

    private void notify_state_cb (GstVideoWindow video_window,
                                  ParamSpec      p) {
        this.changelog.log ("TransportState", this.video_window.playback_state);
    }

    private void notify_duration_cb (GstVideoWindow window,
                                     ParamSpec      p) {
        this.changelog.log ("CurrentTrackDuration", window.duration);
        this.changelog.log ("CurrentMediaDuration", window.duration);
    }
}
