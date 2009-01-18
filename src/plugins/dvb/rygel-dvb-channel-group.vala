/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel;
using GUPnP;
using DBus;
using Gee;

/**
 * Represents DVB channel group.
 */
public class Rygel.DVBChannelGroup : MediaContainer {
    /* class-wide constants */
    private const string DVB_SERVICE = "org.gnome.DVB";

    private const string GID_PREFIX = "GroupID:";

    public static dynamic DBus.Object channel_list;

    /* Hashmap of (UPnP) IDs to channels */
    private HashMap<string, DVBChannel> channels;

    public HTTPServer http_server;

    private uint gid; /* The DVB Daemon Device Group ID */

    public DVBChannelGroup (uint                gid,
                            string              title,
                            string              parent_id,
                            dynamic DBus.Object channel_list,
                            HTTPServer          http_server) {
        base (GID_PREFIX + gid.to_string (), // UPnP ID
              parent_id,
              title,
              0);
        this.gid = gid;
        //this.upnp_class = "object.container.channelGroup";
        this.channel_list = channel_list;
        this.http_server = http_server;

        this.fetch_channels ();

        this.http_server.item_requested += this.on_item_requested;
    }

    public uint add_channels (DIDLLiteWriter didl_writer,
                              uint           index,
                              uint           requested_count,
                              out uint       total_matches) throws GLib.Error {
        foreach (var channel in channels.get_values ()) {
            channel.serialize (didl_writer);
        }

        total_matches = channels.size;

        return total_matches;
    }

    public DVBChannel find_channel (string id) {
        return this.channels.get (id);
    }

    private void fetch_channels () {
        this.channels = new HashMap<string, DVBChannel> (str_hash, str_equal);

        DBus.Connection connection;
        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error error) {
            critical ("Failed to connect to Session bus: %s\n",
                      error.message);
            return;
        }

        uint[] channel_ids = null;

        try {
            channel_ids = this.channel_list.GetChannels ();
        } catch (GLib.Error error) {
            critical ("error: %s", error.message);
            return;
        }

        foreach (uint channel_id in channel_ids) {
            // Create Channels
            try {
                var channel = new DVBChannel (channel_id,
                                              this.id,
                                              channel_list,
                                              http_server);
                this.channels.set (channel.id, channel);
            } catch (GLib.Error error) {
                critical ("Failed to create DVB Channel object: %s",
                          error.message);
            }
        }

        this.child_count = this.channels.size;
    }

    private void on_item_requested (HTTPServer    http_server,
                                    string        item_id,
                                    out MediaItem item) {
        var channel = this.find_channel (item_id);
        if (channel != null) {
            item = channel;
        }
    }
}

