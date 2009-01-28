/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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

    /* List of channels */
    private ArrayList<DVBChannel> channels;

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
    }

    public Gee.List<DVBChannel> get_channels (uint     offset,
                                              uint     max_count,
                                              out uint child_count)
                                              throws GLib.Error {
        child_count = this.channels.size;

        if (max_count == 0) {
            max_count = child_count;
        }

        uint stop = offset + max_count;
        stop = stop.clamp (0, child_count);

        return this.channels.slice ((int) offset, (int) stop);
    }

    public DVBChannel find_channel (string id) {
        DVBChannel channel = null;
        foreach (var tmp in this.channels) {
            if (tmp.id == id) {
                channel = tmp;
                break;
            }
        }

        return channel;
    }

    private void fetch_channels () {
        this.channels = new ArrayList<DVBChannel> ((EqualFunc) channel_equal);

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
                this.channels.add (channel);
            } catch (GLib.Error error) {
                critical ("Failed to create DVB Channel object: %s",
                          error.message);
            }
        }

        this.child_count = this.channels.size;
    }

    private static bool channel_equal (DVBChannel a, DVBChannel b) {
        return a.id == b.id;
    }
}

