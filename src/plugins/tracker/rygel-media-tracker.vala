/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * Implementation of Tracker-based ContentDirectory service.
 */
public class Rygel.MediaTracker : ContentDirectory {
    public static const int MAX_REQUESTED_COUNT = 128;

    /* FIXME: Make this a static if you know how to initize it */
    private List<TrackerContainer> containers;

    private SearchCriteriaParser search_parser;
    private HTTPServer http_server;

    /* Pubic methods */
    public override void constructed () {
        // Chain-up to base first
        base.constructed ();

        this.http_server = new HTTPServer (this.context, "Tracker");

        this.http_server.item_requested += on_item_requested;

        this.containers = new List<TrackerContainer> ();
        this.containers.append
                        (new TrackerContainer ("16",
                                               this.root_container.id,
                                               "All Images",
                                               "Images",
                                               MediaItem.IMAGE_CLASS,
                                               http_server));
        this.containers.append
                        (new TrackerContainer ("14",
                                               this.root_container.id,
                                               "All Music",
                                               "Music",
                                               MediaItem.MUSIC_CLASS,
                                               http_server));
        this.containers.append
                        (new TrackerContainer ("15",
                                               this.root_container.id,
                                               "All Videos",
                                               "Videos",
                                               MediaItem.VIDEO_CLASS,
                                               http_server));

        // Now we know how many top-level containers we have
        this.root_container.child_count = this.containers.length ();

        this.search_parser = new SearchCriteriaParser ();
    }

    public override void add_children_metadata (DIDLLiteWriter didl_writer,
                                                BrowseArgs     args)
                                                throws GLib.Error {
        TrackerContainer container;

        if (args.requested_count == 0)
            args.requested_count = MAX_REQUESTED_COUNT;

        container = this.find_container_by_id (args.object_id);
        if (container == null)
            args.number_returned = 0;
        else {
            args.number_returned =
                container.add_children_from_db (didl_writer,
                                                args.index,
                                                args.requested_count,
                                                out args.total_matches);
        }

        if (args.number_returned > 0) {
            args.update_id = uint32.MAX;
        } else {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }
    }

    public override void add_metadata (DIDLLiteWriter didl_writer,
                                       BrowseArgs     args) throws GLib.Error {
        bool found = false;

        TrackerContainer container;

        /* First try containers */
        container = find_container_by_id (args.object_id);

        if (container != null) {
            container.serialize (didl_writer);

            found = true;
        } else {
            /* Now try items */
            container = get_item_parent (args.object_id);

            if (container != null)
                found = container.add_item_from_db (didl_writer,
                                                    args.object_id);
        }

        if (!found) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        args.update_id = uint32.MAX;
    }

    public override void add_root_children_metadata (DIDLLiteWriter didl_writer,
                                                     BrowseArgs     args)
                                                     throws GLib.Error {
        foreach (TrackerContainer container in this.containers)
            container.serialize (didl_writer);

        args.total_matches = args.number_returned = this.containers.length ();
        args.update_id = uint32.MAX;
    }

    /* Private methods */
    private TrackerContainer? find_container_by_id (string container_id) {
        TrackerContainer container;

        container = null;

        foreach (TrackerContainer tmp in this.containers)
            if (container_id == tmp.id) {
                container = tmp;

                break;
            }

        return container;
    }

    private TrackerContainer? get_item_parent (string uri) {
        TrackerContainer container = null;
        string category;

        try {
            category = TrackerContainer.get_file_category (uri);
        } catch (GLib.Error error) {
            critical ("failed to find service type for %s: %s",
                      uri,
                      error.message);

            return null;
        }

        foreach (TrackerContainer tmp in this.containers) {
            if (tmp.category == category) {
                container = tmp;

                break;
            }
        }

        return container;
    }

    private void on_item_requested (HTTPServer    http_server,
                                    string        item_id,
                                    out MediaItem item) {
        TrackerContainer container = get_item_parent (item_id);

        if (container != null)
            item = container.get_item_from_db (item_id);
    }
}

