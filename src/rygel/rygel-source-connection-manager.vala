/*
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using GUPnP;

/**
 * UPnP ConnectionManager service for serving end-points (MediaServer).
 */
internal class Rygel.SourceConnectionManager : Rygel.ConnectionManager {
    public override void constructed () {
        base.constructed ();

        var server = this.get_http_server ();
        this.source_protocol_info = server.get_protocol_info ();
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
