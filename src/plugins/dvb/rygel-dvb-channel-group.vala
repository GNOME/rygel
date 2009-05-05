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
    private const string GID_PREFIX = "GroupID:";

    public static dynamic DBus.Object channel_list;

    /* List of channels */
    private ArrayList<DVBChannel> channels;

    private uint gid; /* The DVB Daemon Device Group ID */

    public DVBChannelGroup (uint                gid,
                            string              title,
                            MediaContainer      parent,
                            dynamic DBus.Object channel_list) {
        base (GID_PREFIX + gid.to_string (), // UPnP ID
              parent,
              title,
              0);
        this.gid = gid;
        //this.upnp_class = "object.container.channelGroup";
        this.channel_list = channel_list;

        this.fetch_channels ();
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);

        var channels = this.channels.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>>
                                                (this, callback);
        res.data = channels;
        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                         AsyncResult res)
                                                         throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;
        return simple_res.data;
    }

    public override void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback) {
        MediaObject channel = null;
        foreach (var tmp in this.channels) {
            if (tmp.id == id) {
                channel = tmp;
                break;
            }
        }

        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        res.data = channel;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<MediaObject>) res;
        return simple_res.data;
    }

    public MediaObject? find_object_sync (string id) {
        MediaObject channel = null;
        foreach (var tmp in this.channels) {
            if (tmp.id == id) {
                channel = tmp;
                break;
            }
        }

        return channel;
    }

    private void fetch_channels () {
        this.channels = new ArrayList<DVBChannel> ();

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
                                              this,
                                              channel_list);
                this.channels.add (channel);
            } catch (GLib.Error error) {
                critical ("Failed to create DVB Channel object: %s",
                          error.message);
            }
        }

        this.child_count = this.channels.size;
    }
}

