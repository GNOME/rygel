/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009,2010 Nokia Corporation.
 * Copyright (C) 2012 Openismus GmbH.
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Neha Shanbhag <N.Shanbhag@cablelabs.com>
 *         Sivakumar Mani <siva@orexel.com>
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
using Soup;

internal class Rygel.AVTransport : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:AVTransport";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:AVTransport:2";
    public const string UPNP_TYPE_V1 =
                    "urn:schemas-upnp-org:service:AVTransport:1";
    public const string DESCRIPTION_PATH = "xml/AVTransport2.xml";
    public const string LAST_CHANGE_NS =
                    "urn:schemas-upnp-org:metadata-1-0/AVT/";

    private Session session;
    private string protocol_info;

    public string track_metadata {
        owned get { return this.player.metadata ?? ""; }

        set {
            if (value.has_prefix ("&lt;")) {
                this.player.metadata = this.unescape (value);
            } else {
                this.player.metadata = value;
            }
        }
    }

    public string track_uri {
        owned get {
            if (this.player.uri != null) {
                return Markup.escape_text (this.player.uri);
            } else {
                return "";
            }
        }

        set {
            this.player.uri = value;
        }
    }

    private string _status = "OK";
    public string status {
        get {
            return this._status;
        }

        set {
            this._status = value;

            this.changelog.log ("TransportStatus", this._status);
        }
    }

    public string playback_medium {
        get {
            if (this.controller.uri == "") {
                return "None";
            } else {
                return "Network";
            }
        }
    }

    public string speed {
        owned get {
            return this.player.playback_speed;
        }

        set {
            this.player.playback_speed = value;

            this.changelog.log ("TransportPlaySpeed", this.player.playback_speed);
        }
    }

    private string _mode = "NORMAL";
    public string mode {
        get {
            return this._mode;
        }

        set {
            this._mode = value;

            this.changelog.log ("CurrentPlayMode", this._mode);
        }
    }

    private ChangeLog changelog;
    private MediaPlayer player;
    private PlayerController controller;

    public override void constructed () {
        base.constructed ();
        var plugin = this.root_device.resource_factory as MediaRendererPlugin;

        this.changelog = new ChangeLog (this, LAST_CHANGE_NS);
        this.player = this.get_player ();
        this.controller = plugin.get_controller ();

        query_variable["LastChange"].connect (this.query_last_change_cb);

        action_invoked["SetAVTransportURI"].connect
                                        (this.set_av_transport_uri_cb);
        action_invoked["GetMediaInfo"].connect (this.get_media_info_cb);
        action_invoked["GetMediaInfo_Ext"].connect (this.get_media_info_ex_cb);
        action_invoked["GetTransportInfo"].connect (this.get_transport_info_cb);
        action_invoked["GetPositionInfo"].connect (this.get_position_info_cb);
        action_invoked["GetDeviceCapabilities"].connect
                                        (this.get_device_capabilities_cb);
        action_invoked["GetTransportSettings"].connect
                                        (this.get_transport_settings_cb);
        action_invoked["GetCurrentTransportActions"].connect
                                        (this.get_transport_actions_cb);
        action_invoked["Stop"].connect (this.stop_cb);
        action_invoked["Play"].connect (this.play_cb);
        action_invoked["Pause"].connect (this.pause_cb);
        action_invoked["Seek"].connect (this.seek_cb);
        action_invoked["Next"].connect (this.next_cb);
        action_invoked["Previous"].connect (this.previous_cb);
        action_invoked["X_DLNA_GetBytePositionInfo"].connect
                                        (this.x_dlna_get_byte_position_info_cb);

        this.controller.notify["playback-state"].connect (this.notify_state_cb);
        this.controller.notify["n-tracks"].connect (this.notify_n_tracks_cb);
        this.controller.notify["track"].connect (this.notify_track_cb);
        this.controller.notify["uri"].connect (this.notify_uri_cb);
        this.controller.notify["metadata"].connect (this.notify_meta_data_cb);

        this.player.notify["duration"].connect (this.notify_duration_cb);
        this.player.notify["uri"].connect (this.notify_track_uri_cb);
        this.player.notify["metadata"].connect (this.notify_track_meta_data_cb);

        var proxy = Environment.get_variable ("http_proxy");
        if (proxy != null) {
            if (!proxy.has_prefix ("http://") &&
                !proxy.has_prefix ("https://")) {
                proxy = "http://" + proxy;
            }
            this.session = new Session.with_options (Soup.SESSION_PROXY_URI,
                                                     new Soup.URI (proxy));
        } else {
            this.session = new Session ();
        }
        this.protocol_info = plugin.get_protocol_info ();
    }

    private MediaPlayer get_player () {
        var plugin = this.root_device.resource_factory as MediaRendererPlugin;

        return plugin.get_player ();
    }

    private void query_last_change_cb (Service        service,
                                       string         variable,
                                       ref Value      value) {
        // Send current state
        ChangeLog log = new ChangeLog (null, LAST_CHANGE_NS);

        log.log ("TransportState",               this.player.playback_state);
        log.log ("CurrentTransportActions",
                 this.controller.current_transport_actions);
        log.log ("TransportStatus",              this.status);
        log.log ("PlaybackStorageMedium",        this.playback_medium);
        log.log ("RecordStorageMedium",          "NOT_IMPLEMENTED");
        log.log ("PossiblePlaybackStorageMedia", "None,Network");
        log.log ("PossibleRecordStorageMedia",   "NOT_IMPLEMENTED");
        log.log ("CurrentPlayMode",              this.mode);
        log.log ("TransportPlaySpeed",           this.player.playback_speed);
        log.log ("RecordMediumWriteStatus",      "NOT_IMPLEMENTED");
        log.log ("CurrentRecordQualityMode",     "NOT_IMPLEMENTED");
        log.log ("PossibleRecordQualityModes",   "NOT_IMPLEMENTED");
        log.log ("NumberOfTracks",               this.controller.n_tracks.to_string ());
        log.log ("CurrentTrack",                 this.controller.track.to_string ());
        log.log ("CurrentTrackDuration",         this.player.duration_as_str);
        log.log ("CurrentMediaDuration",         this.player.duration_as_str);
        log.log ("CurrentTrackMetaData",
                 Markup.escape_text (this.track_metadata));
        log.log ("AVTransportURIMetaData",
                 Markup.escape_text (this.controller.metadata));
        log.log ("CurrentTrackURI",              this.track_uri);
        log.log ("AVTransportURI",               this.controller.uri);
        log.log ("NextAVTransportURI",           "NOT_IMPLEMENTED");
        log.log ("NextAVTransportURIMetaData",   "NOT_IMPLEMENTED");

        value.init (typeof (string));
        value.set_string (log.finish ());
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
            action.return_error (718, _("Invalid InstanceID"));

            return false;
        }

        return true;
    }

    private void set_av_transport_uri_cb (Service       service,
                                          ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string _uri, _metadata;

        action.get ("CurrentURI",
                        typeof (string),
                        out _uri,
                    "CurrentURIMetaData",
                        typeof (string),
                        out _metadata);

        // remove current playlist handler
        this.controller.set_playlist (null);
        if (_uri.has_prefix ("http://") || _uri.has_prefix ("https://")) {
            var message = new Message ("HEAD", _uri);
            message.request_headers.append ("getContentFeatures.dlna.org",
                                            "1");
            message.finished.connect ((msg) => {
                if ((msg.status_code == Status.MALFORMED ||
                     msg.status_code == Status.BAD_REQUEST ||
                     msg.status_code == Status.METHOD_NOT_ALLOWED ||
                     msg.status_code == Status.NOT_IMPLEMENTED) &&
                    msg.method == "HEAD") {
                    debug ("Peer does not support HEAD, trying GET");
                    msg.method = "GET";
                    msg.got_headers.connect ((msg) => {
                        this.session.cancel_message (msg, msg.status_code);
                    });

                    this.session.queue_message (msg, null);

                    return;
                }

                if (msg.status_code != Status.OK) {
                    warning ("Failed to access %s: %s",
                             _uri,
                             msg.reason_phrase);

                    action.return_error (716, _("Resource not found"));

                    return;
                } else {
                    var mime = msg.response_headers.get_one ("Content-Type");
                    var features = msg.response_headers.get_one
                                        ("contentFeatures.dlna.org");

                    if (!this.is_valid_mime_type (mime) &&
                        !this.is_playlist (mime, features)) {
                        action.return_error (714, _("Illegal MIME-type"));

                        return;
                    }

                    this.controller.metadata = _metadata;
                    this.controller.uri = _uri;

                    if (this.is_playlist (mime, features)) {
                        // Delay returning the action until we got some
                        this.handle_playlist.begin (action);
                    } else {
                        // some other track
                        this.player.mime_type = mime;
                        if (features != null) {
                            this.player.content_features = features;
                        } else {
                            this.player.content_features = "*";
                        }

                        // Track == Media
                        this.track_metadata = _metadata;
                        this.track_uri = _uri;
                        this.controller.n_tracks = 1;
                        this.controller.track = 1;

                        action.return ();
                    }
                }
            });
            this.session.queue_message (message, null);
        } else {
            this.controller.metadata = _metadata;
            this.controller.uri = _uri;

            this.track_metadata = _metadata;
            this.track_uri = _uri;

            if (_uri == "") {
                this.controller.n_tracks = 0;
                this.controller.track = 0;
            } else {
                this.controller.n_tracks = 1;
                this.controller.track = 1;
            }

            action.return ();
        }
    }

    private bool is_valid_mime_type (string? mime) {
        if (mime == null) {
            return false;
        }

        var normalized = mime.down ().replace (" ", "");

        return normalized in this.player.get_mime_types ();
    }

    private void get_media_info_cb (Service       service,
                                    ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string media_duration;
        if (this.controller.n_tracks > 1) {
            // We don't know the size of the playlist. Might need change if we
            // support playlists whose size we know in advance
            media_duration = "0:00:00";
        } else {
            media_duration = this.player.duration_as_str;
        }

        action.set ("NrTracks",
                        typeof (uint),
                        this.controller.n_tracks,
                    "MediaDuration",
                        typeof (string),
                        media_duration,
                    "CurrentURI",
                        typeof (string),
                        this.controller.uri,
                    "CurrentURIMetaData",
                        typeof (string),
                        this.controller.metadata,
                    "NextURI",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "NextURIMetaData",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "PlayMedium",
                        typeof (string),
                        this.playback_medium,
                    "RecordMedium",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "WriteStatus",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return ();
    }

    private void get_media_info_ex_cb (Service       service,
                                       ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string media_duration;
        if (this.controller.n_tracks > 1) {
            // We don't know the size of the playlist. Might need change if we
            // support playlists whose size we know in advance
            media_duration = "0:00:00";
        } else {
            media_duration = this.player.duration_as_str;
        }

        action.set ("CurrentType",
                        typeof (string),
                        "NO_MEDIA",
                    "NrTracks",
                        typeof (uint),
                        this.controller.n_tracks,
                    "MediaDuration",
                        typeof (string),
                        media_duration,
                    "CurrentURI",
                        typeof (string),
                        this.controller.uri,
                    "CurrentURIMetaData",
                        typeof (string),
                        this.controller.metadata,
                    "NextURI",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "NextURIMetaData",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "PlayMedium",
                        typeof (string),
                        this.playback_medium,
                    "RecordMedium",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "WriteStatus",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return ();
    }


    private void get_transport_info_cb (Service       service,
                                        ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("CurrentTransportState",
                        typeof (string),
                        this.player.playback_state,
                    "CurrentTransportStatus",
                        typeof (string),
                        this.status,
                    "CurrentSpeed",
                        typeof (string),
                        this.player.playback_speed);

        action.return ();
    }

    private void get_transport_actions_cb (Service       service,
                                           ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("Actions",
                        typeof (string),
                        this.controller.current_transport_actions);

        action.return ();
    }

    private void get_position_info_cb (Service       service,
                                       ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("Track",
                        typeof (uint),
                        this.controller.track,
                    "TrackDuration",
                        typeof (string),
                        this.player.duration_as_str,
                    "TrackMetaData",
                        typeof (string),
                        this.track_metadata,
                    "TrackURI",
                        typeof (string),
                        this.track_uri,
                    "RelTime",
                        typeof (string),
                        this.player.position_as_str,
                    "AbsTime",
                        typeof (string),
                        this.player.position_as_str,
                    "RelCount",
                        typeof (int),
                        int.MAX,
                    "AbsCount",
                        typeof (int),
                        int.MAX);

        action.return ();
    }

    private void get_device_capabilities_cb (Service       service,
                                             ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("PlayMedia",
                        typeof (string),
                        "None,Network",
                    "RecMedia",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "RecQualityModes",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return ();
    }

    private void get_transport_settings_cb (Service       service,
                                            ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("PlayMode",
                        typeof (string),
                        this.mode,
                    "RecQualityMode",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return ();
    }

    private void stop_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        this.player.playback_state = "STOPPED";

        action.return ();
    }

    private void play_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string speed;

        action.get ("Speed", typeof (string), out speed);
        if (!(speed in this.player.allowed_playback_speeds)) {
            action.return_error (717, _("Play speed not supported"));

            return;
        }

        // Speed change will take effect when playback state is changed
        this.player.playback_speed = speed;
        this.player.playback_state = "PLAYING";

        action.return ();
    }

    private void pause_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (this.player.playback_state != "PLAYING") {
            action.return_error (701, _("Transition not available"));

            return;
        }

        this.player.playback_state = "PAUSED_PLAYBACK";

        action.return ();
    }

    private void seek_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string unit, target;

        action.get ("Unit",
                        typeof (string),
                        out unit,
                    "Target",
                        typeof (string),
                        out target);
        switch (unit) {
        case "ABS_TIME":
        case "REL_TIME":
            var seek_target = TimeUtils.time_from_string (target);
            if (unit != "ABS_TIME") {
                seek_target += this.player.position;
            }
            debug ("Seeking to %lld sec", seek_target / TimeSpan.SECOND);

            if (!this.player.can_seek) {
                action.return_error (710, _("Seek mode not supported"));

                return;
            }

            if (!this.player.seek (seek_target)) {
                action.return_error (711, _("Illegal seek target"));

                return;
            }

            action.return ();

            return;
        case "REL_COUNT":
        case "X_DLNA_REL_BYTE":
        case "ABS_COUNT":
            var seek_target = int64.parse (target);

            if (unit != "ABS_COUNT") {
                seek_target += this.player.byte_position;
            }
            debug ("Seeking to %lld bytes.", seek_target);

            if (!this.player.can_seek_bytes) {
                action.return_error (710, _("Seek mode not supported"));

                return;
            }

            if (!this.player.seek_bytes (seek_target)) {
                action.return_error (711, _("Illegal seek target"));

                return;
            }

            action.return ();

            return;
        case "TRACK_NR":
            debug ("Setting track to %s.", target);
            var track = int.parse (target);

            if (track < 1 || track > this.controller.n_tracks) {
                action.return_error (711, _("Illegal seek target"));

                return;
            }

            this.controller.track = track;

            action.return();

            break;
        default:
            action.return_error (710, _("Seek mode not supported"));

            return;
        }
    }

    private void next_cb (Service service, ServiceAction action) {
        if (this.controller.next ()) {
            action.return ();
        } else {
            action.return_error (711, _("Illegal seek target"));
        }
    }

    private void previous_cb (Service service, ServiceAction action) {
        if (this.controller.previous ()) {
            action.return ();
        } else {
            action.return_error (711, _("Illegal seek target"));
        }
    }

    private void x_dlna_get_byte_position_info_cb (Service       service,
                                                   ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (this.controller.uri == "") {
            action.set ("TrackSize",
                            typeof (string),
                            "",
                        "RelByte",
                            typeof (string),
                            "",
                        "AbsByte",
                            typeof (string),
                            "");
        } else {
            var position = this.player.byte_position.to_string ();
            action.set ("TrackSize",
                            typeof (string),
                            this.player.size.to_string (),
                        "RelByte",
                            typeof (string),
                            position,
                        "AbsByte",
                            typeof (string),
                            position);
        }

        action.return ();
    }

    private void notify_state_cb (Object player, ParamSpec p) {
        var state = this.player.playback_state;
        this.changelog.log ("TransportState", state);
        this.changelog.log ("CurrentTransportActions",
                            this.controller.current_transport_actions);
    }

    private void notify_n_tracks_cb (Object player, ParamSpec p) {
        this.changelog.log ("NumberOfTracks",
                            this.controller.n_tracks.to_string ());
    }

    private void notify_track_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrack",
                            this.controller.track.to_string ());
    }

   private void notify_duration_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrackDuration",
                            this.player.duration_as_str);
        this.changelog.log ("CurrentMediaDuration",
                            this.player.duration_as_str);
    }

    private void notify_track_uri_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrackURI", this.track_uri);
    }

    private void notify_uri_cb (Object player, ParamSpec p) {
        this.changelog.log ("AVTransportURI", this.controller.uri);
    }

    private void notify_track_meta_data_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrackMetaData",
                            Markup.escape_text (this.track_metadata));
    }

    private void notify_meta_data_cb (Object player, ParamSpec p) {
        this.changelog.log ("AVTransportURIMetaData",
                            Markup.escape_text (this.controller.metadata));
    }

    private async void handle_playlist (ServiceAction action) {
        var message = new Message ("GET", this.controller.uri);
        this.session.queue_message (message, () => {
            handle_playlist.callback ();
        });
        yield;

        if (message.status_code != 200) {
            action.return_error (716, _("Resource not found"));

            return;
        }

        unowned string xml_string = (string) message.response_body.data;

        var collection = new MediaCollection.from_string (xml_string);
        if (collection.get_items ().length () == 0) {
            // FIXME: Return a more sensible error here.
            action.return_error (716, _("Resource not found"));

            return;
        }

        this.controller.set_playlist (collection);

        action.return ();
    }

    private string unescape (string input) {
        var result = input.replace ("&quot;", "\"");
        result = result.replace ("&lt;", "<");
        result = result.replace ("&gt;", ">");
        result = result.replace ("&apos;", "'");
        result = result.replace ("&amp;", "&");

        return result;
    }

    private bool is_playlist (string? mime, string? features) {
        return mime == "text/xml" && features != null &&
               features.has_prefix ("DLNA.ORG_PN=DIDL_S");
    }
}
