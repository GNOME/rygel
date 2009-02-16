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
 * Represents the root container for DVB media content hierarchy.
 */
public class Rygel.DVBRootContainer : MediaContainer {
    // class-wide constants
    private const string DVB_SERVICE = "org.gnome.DVB";
    private const string MANAGER_PATH = "/org/gnome/DVB/Manager";
    private const string MANAGER_IFACE = "org.gnome.DVB.Manager";
    private const string CHANNEL_LIST_IFACE = "org.gnome.DVB.ChannelList";

    public dynamic DBus.Object manager;

    private ArrayList<DVBChannelGroup> groups;

    public DVBRootContainer (string title) {
        base.root (title, 0);

        this.groups = new ArrayList<DVBChannelGroup> ();

        try {
            DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

            // Get a proxy to DVB Manager object
            this.manager = connection.get_object (
                                        DVBRootContainer.DVB_SERVICE,
                                        DVBRootContainer.MANAGER_PATH,
                                        DVBRootContainer.MANAGER_IFACE);

            this.fetch_device_groups (connection);
        } catch (DBus.Error error) {
            critical ("Failed to fetch device groups: %s\n", error.message);
        }
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        var groups = this.groups.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>>
                                                (this, callback);
        res.data = groups;
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
        // First try groups
        MediaObject media_object = find_group_by_id (id);

        if (media_object == null) {
            media_object = find_channel_by_id (id);
        }

        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        res.data = media_object;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<MediaObject>) res;
        return simple_res.data;
    }

    // Private methods
    private void fetch_device_groups (DBus.Connection connection)
                                      throws GLib.Error {
        uint[] dev_groups = null;

        dev_groups = this.manager.GetRegisteredDeviceGroups ();

        foreach (uint group_id in dev_groups) {
            string channel_list_path = null;
            string group_name =  null;

            channel_list_path = manager.GetChannelList (group_id);

            // Get the name of the group
            group_name = manager.GetDeviceGroupName (group_id);

            // Get a proxy to DVB ChannelList object
            dynamic DBus.Object channel_list = connection.get_object
                                        (DVBRootContainer.DVB_SERVICE,
                                         channel_list_path,
                                         DVBRootContainer.CHANNEL_LIST_IFACE);

            // Create ChannelGroup for each registered device group
            this.groups.add (new DVBChannelGroup (group_id,
                                                  group_name,
                                                  this,
                                                  channel_list));
        }

        this.child_count = this.groups.size;
    }

    private DVBChannelGroup? find_group_by_id (string id) {
        DVBChannelGroup group = null;

        foreach (DVBChannelGroup tmp in this.groups) {
            if (id == tmp.id) {
                group = tmp;

                break;
            }
        }

        return group;
    }

    private MediaObject find_channel_by_id (string id) throws GLib.Error {
        MediaObject channel = null;

        foreach (DVBChannelGroup group in this.groups) {
            channel = group.find_object_sync (id);
            if (channel != null) {
                break;
            }
        }

        return channel;
    }
}

