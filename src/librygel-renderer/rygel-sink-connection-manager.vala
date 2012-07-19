/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

internal class Rygel.SinkConnectionManager : Rygel.ConnectionManager {
    private MediaPlayer player;

    public override void constructed () {
        base.constructed ();

        this.rcs_id = 0;
        this.av_transport_id = 0;
        this.direction = "Input";

        var plugin = this.root_device.resource_factory as MediaRendererPlugin;
        this.player = plugin.get_player ();
        var protocols = this.player.get_protocols ();

        foreach (var protocol in protocols) {
            if (protocols[0] != protocol) {
                this.sink_protocol_info += ",";
            }
            var mime_types = this.player.get_mime_types ();

            foreach (var mime_type in mime_types) {
                if (mime_types[0] != mime_type) {
                    this.sink_protocol_info += ",";
                }

                this.sink_protocol_info += protocol + ":*:" + mime_type + ":*";
            }
        }
    }
}
