/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2009-2011 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *         Jens Georg <jensg@openismus.com>
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

using GUPnP;
using Gee;

/**
 * UPnP ConnectionManager service for serving end-points (MediaServer).
 */
internal class Rygel.SourceConnectionManager : Rygel.ConnectionManager {
    public override void constructed () {
        base.constructed ();

        this.rcs_id = -1;
        this.av_transport_id = -1;
        this.direction = "Output";

        foreach (var protocol_info in this.get_protocol_info ()) {
            if (this.source_protocol_info != "") {
                // No comma before the first one
                this.source_protocol_info += ",";
            }

            this.source_protocol_info += protocol_info.to_string ();
        }
    }

    private ArrayList<ProtocolInfo> get_protocol_info () {
        var server = this.get_http_server ();
        var protocol_infos = server.get_protocol_info ();

        var plugin = this.root_device.resource_factory as MediaServerPlugin;
        unowned GLib.List<DLNAProfile> profiles = plugin.supported_profiles;

        var protocol = server.get_protocol ();

        foreach (var profile in profiles) {
            var protocol_info = new ProtocolInfo ();

            protocol_info.protocol = protocol;
            protocol_info.mime_type = profile.mime;
            protocol_info.dlna_profile = profile.name;

            if (!(protocol_info in protocol_infos)) {
                protocol_infos.insert (0, protocol_info);
            }
        }

        return protocol_infos;
    }

    private HTTPServer get_http_server () {
        HTTPServer server = null;

        var root_device = (Rygel.RootDevice) this.root_device;

        // Find the ContentDirectory service attached to this root device.
        foreach (var service in root_device.services) {
            if (service.get_type().is_a (typeof (Rygel.ContentDirectory))) {
                var content_directory = (Rygel.ContentDirectory) service;
                server = content_directory.http_server;
            }
        }

        return server;
    }
}
