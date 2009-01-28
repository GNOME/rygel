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
 * Implementation of DVB ContentDirectory service.
 */
public class Rygel.DVBContentDir : ContentDirectory {
    // class-wide constants
    private const string DVB_SERVICE = "org.gnome.DVB";
    private const string MANAGER_PATH = "/org/gnome/DVB/Manager";
    private const string MANAGER_IFACE = "org.gnome.DVB.Manager";
    private const string CHANNEL_LIST_IFACE = "org.gnome.DVB.ChannelList";

    public dynamic DBus.Object manager;

    private ArrayList<DVBChannelGroup> groups;

    // Pubic methods
    public override void constructed () {
        // Chain-up to base first
        base.constructed ();

        DBus.Connection connection;
        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error error) {
            critical ("Failed to connect to Session bus: %s\n",
                      error.message);
            return;
        }

        this.groups = new ArrayList<DVBChannelGroup> ();

        // Get a proxy to DVB Manager object
        this.manager = connection.get_object (DVBContentDir.DVB_SERVICE,
                                              DVBContentDir.MANAGER_PATH,
                                              DVBContentDir.MANAGER_IFACE);
        uint[] dev_groups = null;

        try {
            dev_groups = this.manager.GetRegisteredDeviceGroups ();
        } catch (GLib.Error error) {
            critical ("error: %s", error.message);
            return;
        }

        foreach (uint group_id in dev_groups) {
            string channel_list_path = null;
            string group_name =  null;

            try {
                channel_list_path = manager.GetChannelList (group_id);

                // Get the name of the group
                group_name = manager.GetDeviceGroupName (group_id);
            } catch (GLib.Error error) {
                critical ("error: %s", error.message);
                return;
            }

            // Get a proxy to DVB ChannelList object
            dynamic DBus.Object channel_list = connection.get_object
                                        (DVBContentDir.DVB_SERVICE,
                                         channel_list_path,
                                         DVBContentDir.CHANNEL_LIST_IFACE);

            // Create ChannelGroup for each registered device group
            this.groups.add (new DVBChannelGroup (group_id,
                                                  group_name,
                                                  this.root_container.id,
                                                  channel_list,
                                                  this.http_server));
        }
    }

    public override MediaObject find_object_by_id (string object_id)
                                                   throws GLib.Error {
        // First try groups
        MediaObject media_object = find_group_by_id (object_id);

        if (media_object == null) {
            media_object = find_channel_by_id (object_id);
        }

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return media_object;
    }

    public override Gee.List<MediaObject> get_children (
                                                 string   container_id,
                                                 uint     offset,
                                                 uint     max_count,
                                                 out uint child_count)
                                                 throws GLib.Error {
        var group = this.find_group_by_id (container_id);
        if (group == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        var channels = group.get_children (offset,
                                           max_count,
                                           out child_count);
        if (channels == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return channels;
    }

    public override Gee.List<MediaObject> get_root_children (
                                                 uint     offset,
                                                 uint     max_count,
                                                 out uint child_count)
                                                 throws GLib.Error {
        child_count = this.groups.size;

        Gee.List<MediaObject> children = null;

        if (max_count == 0) {
            max_count = child_count;
        }

        uint stop = offset + max_count;

        stop = stop.clamp (0, child_count);
        children = this.groups.slice ((int) offset, (int) stop);

        if (children == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return children;
    }

    // Private methods
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
            channel = group.find_object_by_id (id);
            if (channel != null) {
                break;
            }
        }

        return channel;
    }
}

