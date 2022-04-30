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

    protected string sink_protocol_info;
    protected string connection_ids;
    protected string source_protocol_info;

    protected int rcs_id;
    protected int av_transport_id;
    protected string direction;

    public override void constructed () {
        base.constructed ();

        this.sink_protocol_info   = "";
        this.source_protocol_info = "";
        this.connection_ids       = "0";

        this.query_variable["SourceProtocolInfo"].connect
                                        (this.query_source_protocol_info_cb);
        this.query_variable["SinkProtocolInfo"].connect
                                        (this.query_sink_protocol_info_cb);
        this.query_variable["CurrentConnectionIDs"].connect
                                        (this.query_current_connection_ids_cb);

        this.action_invoked["GetProtocolInfo"].connect
                                        (this.get_protocol_info_cb);
        this.action_invoked["GetCurrentConnectionIDs"].connect
                                        (this.get_current_connection_ids_cb);
        this.action_invoked["GetCurrentConnectionInfo"].connect
                                        (this.get_current_connection_info_cb);
    }

    public virtual string get_current_protocol_info () {
        return "";
    }

    private void query_source_protocol_info_cb (Service   cm,
                                                string    var,
                                                ref Value val) {
        val.init (typeof (string));
        val.set_string (source_protocol_info);
    }

    private void query_sink_protocol_info_cb (Service   cm,
                                              string    var,
                                              ref Value val) {
        val.init (typeof (string));
        val.set_string (sink_protocol_info);
    }

    private void query_current_connection_ids_cb (Service   cm,
                                                  string    var,
                                                  ref Value val) {
        val.init (typeof (string));
        val.set_string (connection_ids);
    }

    private void get_protocol_info_cb (Service             cm,
                                       ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("Source", typeof (string), source_protocol_info,
                    "Sink",   typeof (string), sink_protocol_info);

        action.return_success ();
    }

    private void get_current_connection_ids_cb (Service             cm,
                                                ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        action.set ("ConnectionIDs", typeof (string), connection_ids);

        action.return_success ();
    }

    private void get_current_connection_info_cb (Service             cm,
                                                 ServiceAction action) {
        string connection_id;

        action.get ("ConnectionID", typeof (string), out connection_id);
        if (connection_id == null || action.get_argument_count () != 1 ||
            (connection_id != "0" && int.parse (connection_id) == 0)) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        if (connection_id != "0") {
            action.return_error (706, _("Invalid connection reference"));

            return;
        }

        action.set ("RcsID",
                        typeof (int),
                        this.rcs_id,
                    "AVTransportID",
                        typeof (int),
                        this.av_transport_id,
                    "ProtocolInfo",
                        typeof (string),
                        this.get_current_protocol_info (),
                    "PeerConnectionManager",
                        typeof (string),
                        "",
                    "PeerConnectionID",
                        typeof (int),
                        -1,
                    "Direction",
                        typeof (string),
                        this.direction,
                    "Status",
                        typeof (string),
                        "OK");

        action.return_success ();
    }
}
