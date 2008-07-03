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

using GLib;
using GUPnP;

public class GUPnP.ConnectionManager : Service {
    private string source_protocol_info = "http-get:*:audio/mpeg:*,http-get:*:application/ogg:*,http-get:*:audio/x-vorbis:*,http-get:*:audio/x-ms-wma:*,http-get:*:audio/x-ms-asf:*,http-get:*:audio/x-flac:*,http-get:*:audio/x-mod:*,http-get:*:audio/x-wav:*,http-get:*:audio/x-ac3:*,http-get:*:audio/x-m4a:*,http-get:*:video/x-theora:*,http-get:*:video/x-dirac:*,http-get:*:video/x-wmv:*,http-get:*:video/x-wma:*,http-get:*:video/x-msvideo:*,http-get:*:video/x-3ivx:*,http-get:*:video/x-3ivx:*,http-get:*:video/x-matroska:*,http-get:*:video/mpeg:*,http-get:*:video/x-ms-asf:*,http-get:*:video/x-divx:*,http-get:*:video/x-ms-wmv:*";
    private string sink_protocol_info   = "";
    private string connection_ids       = "0";

    construct {
        this.query_variable["SourceProtocolInfo"] +=
                        this.query_source_protocol_info_cb;
        this.query_variable["SinkProtocolInfo"] +=
                        this.query_sink_protocol_info_cb;
        this.query_variable["CurrentConnectionIDs"] +=
                        this.query_current_connection_ids_cb;

        this.action_invoked["GetProtocolInfo"] += this.get_protocol_info_cb;
        this.action_invoked["GetCurrentConnectionIDs"] +=
                        this.get_current_connection_ids_cb;
        this.action_invoked["GetCurrentConnectionInfo"] +=
                        this.get_current_connection_info_cb;
    }

    private void query_source_protocol_info_cb (ConnectionManager cm,
                                                string            var,
                                                ref Value         val) {
        val.init (typeof (string));
        val.set_string (source_protocol_info);
    }

    private void query_sink_protocol_info_cb (ConnectionManager cm,
                                              string            var,
                                              ref Value         val) {
        val.init (typeof (string));
        val.set_string (sink_protocol_info);
    }

    private void query_current_connection_ids_cb (ConnectionManager cm,
                                                  string            var,
                                                  ref Value         val) {
        val.init (typeof (string));
        val.set_string (connection_ids);
    }

    private void get_protocol_info_cb (ConnectionManager cm,
                                       ServiceAction     action) {
        action.set ("Source", typeof (string), source_protocol_info,
                    "Sink",   typeof (string), sink_protocol_info);

        action.return ();
    }

    private void get_current_connection_ids_cb (ConnectionManager cm,
                                                ServiceAction     action) {
        action.set ("ConnectionIDs", typeof (string), connection_ids);

        action.return ();
    }

    private void get_current_connection_info_cb (ConnectionManager cm,
                                                 ServiceAction     action) {
        int connection_id;

        action.get ("ConnectionID", typeof (int), out connection_id);
        if (connection_id != 0) {
            action.return_error (706, "Invalid connection reference");

            return;
        }

        action.set ("ResID",                 typeof (int),    -1,
                    "AVTransportID",         typeof (int),    -1,
                    "ProtocolInfo",          typeof (string), "",
                    "PeerConnectionManager", typeof (string), "",
                    "PeerConnectionID",      typeof (int),    -1,
                    "Direction",             typeof (string), "Input",
                    "Status",                typeof (string), "Unknown");

        action.return ();
    }
}
