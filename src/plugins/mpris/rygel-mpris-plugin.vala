/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel.MPRIS;
using Rygel.MPRIS.MediaPlayer;
using FreeDesktop;

public class Rygel.MPRIS.Plugin : Rygel.MediaRendererPlugin {
    private const string MEDIA_PLAYER_PATH = "/org/mpris/MediaPlayer2";

    private PlayerProxy actual_player;
    private FreeDesktop.Properties properties;

    private string[] mime_types;
    private string[] protocols;

    public Plugin (string   service_name,
                   string   title,
                   string[] mime_types,
                   string[] schemes) {
        base (service_name, title);

        this.mime_types = mime_types;
        this.protocols = this.schemes_to_protocols (schemes);

        try {
            // Create proxy to MediaPlayer.Player iface
            this.actual_player = Bus.get_proxy_sync (BusType.SESSION,
                                                     DBUS_SERVICE,
                                                     MEDIA_PLAYER_PATH);
            // Create proxy to FreeDesktop.Properties iface
            this.properties = Bus.get_proxy_sync (BusType.SESSION,
                                                  service_name,
                                                  MEDIA_PLAYER_PATH);
        } catch (GLib.Error err) {
            critical ("Failed to connect to session bus: %s", err.message);
        }
    }

    public override Rygel.MediaPlayer? get_player () {
        return new MPRIS.Player (this.actual_player,
                                 this.properties,
                                 this.mime_types,
                                 this.protocols);
    }

    private string[] schemes_to_protocols (string[] schemes) {
        var protocols = new string[schemes.length];

        for (var i = 0; i < schemes.length; i++) {
            protocols[i] = this.scheme_to_protocol (schemes[i]);
        }

        return protocols;
    }

    private string scheme_to_protocol (string scheme) {
        switch (scheme) {
        case "http":
            return "http-get";
        case "file":
            return "internal";
        default:
            return scheme;
        }
    }
}

