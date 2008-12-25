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
    private const string CHANNEL_LIST_PATH_ROOT = "/org/gnome/DVB/ChannelList/";
    private const string CHANNEL_LIST_IFACE = "org.gnome.DVB.ChannelList";

    private const string GID_PREFIX = "GroupID:";
    private const string TITLE_PREFIX = "Group ";

    public static dynamic DBus.Object channel_list;

    /* Hashmap of (UPnP) IDs to channels */
    private HashMap<string, DVBChannel> channels;

    public Streamer streamer;

    private uint gid; /* The DVB Daemon Device Group ID */

    public DVBChannelGroup (uint     gid,
                            string   parent_id,
                            Streamer streamer) {
        base (GID_PREFIX + gid.to_string (), // UPnP ID
              parent_id,
              TITLE_PREFIX + gid.to_string (),
              0);
        this.gid = gid;
        //this.upnp_class = "object.container.channelGroup";
        this.streamer = streamer;

        channels = new HashMap<string, DVBChannel> (str_hash, str_equal);

        DBus.Connection connection;
        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error error) {
            critical ("Failed to connect to Session bus: %s\n",
                      error.message);
            return;
        }

        string channel_list_path = DVBChannelGroup.CHANNEL_LIST_PATH_ROOT +
                                   gid.to_string ();

        // Get a proxy to DVB ChannelList object
        this.channel_list = connection.get_object
                                    (DVBChannelGroup.DVB_SERVICE,
                                     channel_list_path,
                                     DVBChannelGroup.CHANNEL_LIST_IFACE);
        uint[] channel_ids = null;

        try {
            channel_ids = this.channel_list.GetChannels ();
        } catch (GLib.Error error) {
            critical ("error: %s", error.message);
            return;
        }

        foreach (uint channel_id in channel_ids) {
            // Create Channels
            var channel = new DVBChannel (channel_id,
                                          this.id,
                                          channel_list,
                                          streamer);
            this.channels.set (channel.id, channel);
        }

        this.child_count = this.channels.size;
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

    public DVBChannel find_channel (DIDLLiteWriter didl_writer,
                                    string         id) {
        return this.channels.get (id);
    }
}

