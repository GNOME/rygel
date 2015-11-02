/*
 * Copyright (C) 2008 OpenedHand Ltd.
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Jorn Baayen <jorn@openedhand.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

internal class Rygel.SinkConnectionManager : Rygel.ConnectionManager {
    public override void constructed () {
        base.constructed ();

        this.rcs_id = 0;
        this.av_transport_id = 0;
        this.direction = "Input";

        var plugin = this.root_device.resource_factory as MediaRendererPlugin;
        this.sink_protocol_info = plugin.get_protocol_info ();
    }

    public override string get_current_protocol_info () {
        var plugin = this.root_device.resource_factory as MediaRendererPlugin;
        var player = plugin.get_player ();

        return player.protocol_info;
    }
}
