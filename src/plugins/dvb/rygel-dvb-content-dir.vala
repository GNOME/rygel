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

    private List<DVBChannelGroup> groups;

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

        Streamer streamer = new Streamer (this.context, "DVB");

        this.groups = new List<DVBChannelGroup> ();
        foreach (uint group_id in dev_groups) {
            string channel_list_path = null;
            try {
                channel_list_path = manager.GetChannelList (group_id);
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
            this.groups.append (new DVBChannelGroup (group_id,
                                                     this.root_container.id,
                                                     channel_list,
                                                     streamer));
        }
    }

    public override void add_children_metadata (DIDLLiteWriter didl_writer,
                                                BrowseArgs     args)
                                                throws GLib.Error {
        DVBChannelGroup group;

        group = this.find_group_by_id (args.object_id);
        if (group == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        args.number_returned = group.add_channels (didl_writer,
                                                   args.index,
                                                   args.requested_count,
                                                   out args.total_matches);
        args.update_id = uint32.MAX;
    }

    public override void add_metadata (DIDLLiteWriter didl_writer,
                                       BrowseArgs     args) throws GLib.Error {
        bool found = false;

        DVBChannelGroup group;

        // First try groups
        group = find_group_by_id (args.object_id);

        if (group != null) {
            group.serialize (didl_writer);

            found = true;
        } else {
            // Now try channels
            found = this.add_channel (didl_writer, args.object_id);
        }

        if (!found) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        args.update_id = uint32.MAX;
    }

    public override void add_root_children_metadata (DIDLLiteWriter didl_writer,
                                                     BrowseArgs     args)
                                                     throws GLib.Error {
        foreach (DVBChannelGroup group in this.groups)
            group.serialize (didl_writer);

        args.total_matches = args.number_returned = this.groups.length ();
        args.update_id = uint32.MAX;
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

    private bool add_channel (DIDLLiteWriter didl_writer,
                              string         id) throws GLib.Error {
        bool found = false;

        foreach (DVBChannelGroup group in this.groups) {
            var channel = group.find_channel (id);
            if (channel != null) {
                channel.serialize (didl_writer);
                found = true;
                break;
            }
        }

        return found;
    }
}

