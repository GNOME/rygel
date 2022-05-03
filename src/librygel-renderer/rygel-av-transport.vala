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
                return "NONE";
            } else {
                return "NETWORK";
            }
        }
    }

    public string possible_playback_media {
        get {
            return "NONE,NETWORK";
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
        action_invoked["SetNextAVTransportURI"].connect
                                        (this.set_next_av_transport_uri_cb);
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
        action_invoked["SetPlayMode"].connect (this.set_play_mode_cb);

        this.controller.notify["playback-state"].connect (this.notify_state_cb);
        this.controller.notify["n-tracks"].connect (this.notify_n_tracks_cb);
        this.controller.notify["track"].connect (this.notify_track_cb);
        this.controller.notify["uri"].connect (this.notify_uri_cb);
        this.controller.notify["metadata"].connect (this.notify_meta_data_cb);
        this.controller.notify["track-uri"].connect (this.notify_track_uri_cb);
        this.controller.notify["track-metadata"].connect (this.notify_track_meta_data_cb);
        this.controller.notify["next-uri"].connect (this.notify_next_uri_cb);
        this.controller.notify["next-metadata"].connect (this.notify_next_meta_data_cb);
        this.controller.notify["play-mode"].connect (this.notify_play_mode_cb);

        this.player.notify["duration"].connect (this.notify_duration_cb);

        // Work-around for missing default values on properties in interfaces,
        // see bgo#702774
        if (this.player.user_agent == null) {
            this.player.user_agent = "Rygel/%s DLNADOC/1.50 UPnP/1.0".printf
                                        (BuildConfig.PACKAGE_VERSION);
        }

        this.session = new Session ();
        this.session.set_user_agent (this.player.user_agent);

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

        log.log ("TransportState",               this.controller.playback_state);
        log.log ("CurrentTransportActions",
                 this.controller.current_transport_actions);
        log.log ("TransportStatus",              this.status);
        log.log ("PlaybackStorageMedium",        this.playback_medium);
        log.log ("RecordStorageMedium",          "NOT_IMPLEMENTED");
        log.log ("PossiblePlaybackStorageMedia", this.possible_playback_media);
        log.log ("PossibleRecordStorageMedia",   "NOT_IMPLEMENTED");
        log.log ("CurrentPlayMode",              this.controller.play_mode);
        log.log ("TransportPlaySpeed",           this.player.playback_speed);
        log.log ("RecordMediumWriteStatus",      "NOT_IMPLEMENTED");
        log.log ("CurrentRecordQualityMode",     "NOT_IMPLEMENTED");
        log.log ("PossibleRecordQualityModes",   "NOT_IMPLEMENTED");
        log.log ("NumberOfTracks",               this.controller.n_tracks.to_string ());
        log.log ("CurrentTrack",                 this.controller.track.to_string ());
        log.log ("CurrentTrackDuration",         this.player.duration_as_str);
        log.log ("CurrentMediaDuration",         this.player.duration_as_str);
        log.log ("AVTransportURI",               this.controller.uri);
        log.log ("AVTransportURIMetaData",       this.controller.metadata);
        log.log ("CurrentTrackURI",              this.controller.track_uri);
        log.log ("CurrentTrackMetaData",         this.controller.track_metadata);
        log.log ("NextAVTransportURI",           this.controller.next_uri);
        log.log ("NextAVTransportURIMetaData",   this.controller.next_metadata);

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

        this.handle_new_transport_uri.begin (action, _uri, _metadata);
    }

    private void set_next_av_transport_uri_cb (Service       service,
                                               ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string _uri, _metadata;

        action.get ("NextURI",
                        typeof (string),
                        out _uri,
                    "NextURIMetaData",
                        typeof (string),
                        out _metadata);

        this.handle_new_transport_uri.begin (action, _uri, _metadata);
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
                        this.controller.next_uri,
                    "NextURIMetaData",
                        typeof (string),
                        this.controller.next_metadata,
                    "PlayMedium",
                        typeof (string),
                        this.playback_medium,
                    "RecordMedium",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "WriteStatus",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return_success ();
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
                        this.controller.next_uri,
                    "NextURIMetaData",
                        typeof (string),
                        this.controller.next_metadata,
                    "PlayMedium",
                        typeof (string),
                        this.playback_medium,
                    "RecordMedium",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "WriteStatus",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return_success ();
    }


    private void get_transport_info_cb (Service       service,
                                        ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("CurrentTransportState",
                        typeof (string),
                        this.controller.playback_state,
                    "CurrentTransportStatus",
                        typeof (string),
                        this.status,
                    "CurrentSpeed",
                        typeof (string),
                        this.player.playback_speed);

        action.return_success ();
    }

    private void get_transport_actions_cb (Service       service,
                                           ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("Actions",
                        typeof (string),
                        this.controller.current_transport_actions);

        action.return_success ();
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
                        this.controller.track_metadata,
                    "TrackURI",
                        typeof (string),
                        this.controller.track_uri,
                    "RelTime",
                        typeof (string),
                        this.player.position_as_str,
                    "AbsTime",
                        typeof (string),
                        this.player.position_as_str,
                    "RelCount",
                        typeof (int64),
                        this.player.byte_position,
                    "AbsCount",
                        typeof (int64),
                        this.player.byte_position);

        action.return_success ();
    }

    private void get_device_capabilities_cb (Service       service,
                                             ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("PlayMedia",
                        typeof (string),
                        this.possible_playback_media,
                    "RecMedia",
                        typeof (string),
                        "NOT_IMPLEMENTED",
                    "RecQualityModes",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return_success ();
    }

    private void get_transport_settings_cb (Service       service,
                                            ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        action.set ("PlayMode",
                        typeof (string),
                        this.controller.play_mode,
                    "RecQualityMode",
                        typeof (string),
                        "NOT_IMPLEMENTED");

        action.return_success ();
    }

    private void stop_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        this.controller.playback_state = "STOPPED";

        action.return_success ();
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

        if (this.controller.playback_state != "STOPPED"
            && this.controller.playback_state != "PAUSED_PLAYBACK") {
            action.return_error (701, _("Transition not available"));

            return;
        }

        // Speed change will take effect when playback state is changed
        this.player.playback_speed = speed;
        this.controller.playback_state = "PLAYING";

        action.return_success ();
    }

    private void pause_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (!this.controller.can_pause) {
            action.return_error (701, _("Transition not available"));

            return;
        }

        this.controller.playback_state = "PAUSED_PLAYBACK";

        action.return_success ();
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
            debug ("Seeking to %lld sec", seek_target / TimeSpan.SECOND);

            if (!this.player.can_seek) {
                action.return_error (710, _("Seek mode not supported"));

                return;
            }

            if (!this.player.seek (seek_target)) {
                action.return_error (711, _("Illegal seek target"));

                return;
            }

            action.return_success ();

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

            action.return_success ();

            return;
        case "TRACK_NR":
            debug ("Setting track to %s.", target);
            var track = int.parse (target);

            if (track < 1 || track > this.controller.n_tracks) {
                action.return_error (711, _("Illegal seek target"));

                return;
            }

            this.controller.track = track;

            action.return_success ();

            break;
        default:
            action.return_error (710, _("Seek mode not supported"));

            return;
        }
    }

    private void next_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (this.controller.next ()) {
            action.return_success ();
        } else {
            action.return_error (711, _("Illegal seek target"));
        }
    }

    private void previous_cb (Service service, ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        if (this.controller.previous ()) {
            action.return_success ();
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

        action.return_success ();
    }

    private void set_play_mode_cb (Service       service,
                                   ServiceAction action) {
        if (!this.check_instance_id (action)) {
            return;
        }

        string play_mode;

        action.get ("NewPlayMode",
                        typeof (string),
                        out play_mode);

        if (!this.controller.is_play_mode_valid(play_mode)) {
            action.return_error (712, _("Play mode not supported"));
            return;
        }

        this.controller.play_mode = play_mode;

        action.return_success ();
    }

    private void notify_state_cb (Object controller, ParamSpec p) {
        var state = this.controller.playback_state;
        this.changelog.log ("TransportState", state);
        this.changelog.log ("CurrentTransportActions",
                            this.controller.current_transport_actions);
    }

    private void notify_n_tracks_cb (Object controller, ParamSpec p) {
        this.changelog.log ("NumberOfTracks",
                            this.controller.n_tracks.to_string ());
    }

    private void notify_track_cb (Object controller, ParamSpec p) {
        this.changelog.log ("CurrentTrack",
                            this.controller.track.to_string ());
    }

   private void notify_duration_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrackDuration",
                            this.player.duration_as_str);
        this.changelog.log ("CurrentMediaDuration",
                            this.player.duration_as_str);
    }

    private void notify_uri_cb (Object controller, ParamSpec p) {
        this.changelog.log ("AVTransportURI", this.controller.uri);
    }

    private void notify_meta_data_cb (Object player, ParamSpec p) {
        this.changelog.log ("AVTransportURIMetaData",
                            this.controller.metadata);
    }

    private void notify_track_uri_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrackURI", this.controller.track_uri);
    }

    private void notify_track_meta_data_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentTrackMetaData",
                            this.controller.track_metadata);
    }

    private void notify_next_uri_cb (Object controller, ParamSpec p) {
        this.changelog.log ("NextAVTransportURI", this.controller.next_uri);
    }

    private void notify_next_meta_data_cb (Object player, ParamSpec p) {
        this.changelog.log ("NextAVTransportURIMetaData",
                            this.controller.next_metadata);
    }

    private void notify_play_mode_cb (Object player, ParamSpec p) {
        this.changelog.log ("CurrentPlayMode", this.controller.play_mode);
    }

    private MediaCollection? parse_m3u_playlist (Bytes? data) throws Error {
        if (data == null) {
            return null;
        }

        var collection = new MediaCollection ();
        var m_stream = new MemoryInputStream.from_bytes (data);
        var stream = new DataInputStream (m_stream);

        debug ("Trying to parse m3u playlist");
        size_t length;
        var line = stream.read_line (out length);
        while (line != null) {

            // Swallow comments
            while (line != null && line.has_prefix ("#")) {
                line = stream.read_line (out length);
            }

            // No more lines after comments
            if (line == null) {
                break;
            }

            debug ("Adding uri with %s", line);
            var item = collection.add_item ();
            item.upnp_class = "object.item.audioItem";

            var resource = item.add_resource ();
            var pi = new ProtocolInfo.from_string ("*:*:*:*");
            resource.set_protocol_info (pi);
            resource.uri = line.strip ();

            line = stream.read_line (out length);
        }

        return collection;
    }

    private async void handle_playlist (ServiceAction action,
                                        string uri,
                                        string metadata,
                                        string mime,
                                        string features) {
        var message = new Message ("GET", uri);
        Bytes? body = null;

        try {
            body = yield this.session.send_and_read_async (message, Priority.DEFAULT, null);
        } catch (Error error) {
            action.return_error (716, _("Resource not found"));

            return;
        }

        if (message.status_code != 200) {
            action.return_error (716, _("Resource not found"));

            return;
        }

        var content_type = message.response_headers.get_content_type (null);

        MediaCollection collection = null;
        if (content_type.has_suffix ("mpegurl")) {
            debug ("Trying to parse m3u playlist");
            try {
                collection = parse_m3u_playlist (body);
            } catch (Error error) {
                warning (_("Problem parsing playlist: %s"), error.message);
                // FIXME: Return a more sensible error here.
                action.return_error (716, _("Resource not found"));

                return;
            }
        } else {
            unowned string xml_string = (string) body.get_data();
            collection = new MediaCollection.from_string (xml_string);
            if (collection.get_items ().length () == 0) {
                // FIXME: Return a more sensible error here.
                action.return_error (716, _("Resource not found"));

                return;
            }
        }

        switch (action.get_name ()) {
        case "SetAVTransportURI":
            this.controller.set_playlist_uri (uri, metadata, collection);
            break;
        case "SetNextAVTransportURI":
            this.controller.set_next_playlist_uri (uri, metadata, collection);
            break;
        default:
            assert_not_reached ();
        }

        action.return_success ();
    }

    private bool is_playlist (string? mime, string? features) {
        return (mime != null && mime == "text/xml" &&
                features != null &&
                features.has_prefix ("DLNA.ORG_PN=DIDL_S")) ||
                mime.has_suffix ("mpegurl");
    }

    private async void handle_new_transport_uri (ServiceAction action,
                                           string        uri,
                                           string        metadata) {

        if (!uri.has_prefix ("http://") && !uri.has_prefix ("https://")) {
            this.set_single_play_uri (action, uri, metadata, null, null);

            return;
        }

        var new_uri = this.context.rewrite_uri (uri);
        var message = new Message ("HEAD", new_uri);
        message.request_headers.append ("getContentFeatures.dlna.org",
                                        "1");
        message.request_headers.append ("Connection", "close");

        try {
            yield this.session.send_async (message, Priority.DEFAULT, null);
            if (message.status_code == Status.BAD_REQUEST ||
                message.status_code == Status.METHOD_NOT_ALLOWED ||
                message.status_code == Status.NOT_IMPLEMENTED) {
                debug ("Peer does not support HEAD, trying GET");
                message.method = "GET";
                yield this.session.send_async (message, Priority.DEFAULT, null);
            }

            if (message.status_code != Status.OK) {
                // TRANSLATORS: first %s is a URI, the second an explanaition of
                // the error
                warning (_("Failed to access resource at %s: %s"),
                         uri,
                         message.reason_phrase);

                action.return_error (716, _("Resource not found"));

                return;
            }

            var mime = message.response_headers.get_one ("Content-Type");
            var features = message.response_headers.get_one
                                ("contentFeatures.dlna.org");

            if (!this.is_valid_mime_type (mime) &&
                !this.is_playlist (mime, features)) {
                debug ("Unsupported mime type %s", mime);
                action.return_error (714, _("Illegal MIME-type"));

                return;
            }

            if (this.is_playlist (mime, features)) {
                // Delay returning the action
                yield handle_playlist (action,
                                       uri,
                                       metadata,
                                       mime,
                                       features);
            } else {
                this.set_single_play_uri (action, uri, metadata, mime, features);
            }

        } catch (Error error) {
            // TRANSLATORS: first %s is a URI, the second an explanaition of
            // the error
            warning (_("Failed to access resource at %s: %s"),
                    uri,
                    message.reason_phrase);

            action.return_error (716, _("Resource not found"));

            return;
        }
    }

    private void set_single_play_uri (ServiceAction    action,
                                      string           uri,
                                      string           metadata,
                                      string?          mime,
                                      string?          features) {
        switch (action.get_name ()) {
            case "SetAVTransportURI":
                this.controller.set_single_play_uri (uri, metadata, mime, features);
                break;
            case "SetNextAVTransportURI":
                this.controller.set_next_single_play_uri (uri, metadata, mime, features);
                break;
            default:
                assert_not_reached ();
        }

        action.return_success ();
    }
}
