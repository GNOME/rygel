/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali <zeenix@gmail.com>
 *
 * This file is part of Rygel.
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

using GLib;
using GUPnP;

/**
 * Basic implementation of UPnP ConnectionManager service version 2.
 */
public class Rygel.ConnectionManager : Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:ConnectionManager";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:ConnectionManager:2";
    public const string DESCRIPTION_PATH = "xml/ConnectionManager.xml";

    protected string source_protocol_info;
    protected string sink_protocol_info;
    protected string connection_ids;

    public override void constructed () {
        this.sink_protocol_info   = "";
        this.connection_ids       = "0";
        this.source_protocol_info = "http-get:*:*:*";

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

    private void get_protocol_info_cb (ConnectionManager   cm,
                                       owned ServiceAction action) {
        action.set ("Source", typeof (string), source_protocol_info,
                    "Sink",   typeof (string), sink_protocol_info);

        action.return ();
    }

    private void get_current_connection_ids_cb (ConnectionManager   cm,
                                                owned ServiceAction action) {
        action.set ("ConnectionIDs", typeof (string), connection_ids);

        action.return ();
    }

    private void get_current_connection_info_cb (ConnectionManager   cm,
                                                 owned ServiceAction action) {
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
