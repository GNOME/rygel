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
 * Represents the root container for Tracker media content hierarchy.
 */
public class Rygel.TrackerRootContainer : MediaContainer {
    /* FIXME: Make this a static if you know how to initize it */
    private ArrayList<TrackerContainer> containers;

    public TrackerRootContainer (string title, HTTPServer http_server) {
        base.root (title, 0);

        this.containers = new ArrayList<TrackerContainer> ();
        this.containers.add
                        (new TrackerContainer ("16",
                                               this.id,
                                               "All Images",
                                               "Images",
                                               MediaItem.IMAGE_CLASS,
                                               http_server));
        this.containers.add
                        (new TrackerContainer ("14",
                                               this.id,
                                               "All Music",
                                               "Music",
                                               MediaItem.MUSIC_CLASS,
                                               http_server));
        this.containers.add
                        (new TrackerContainer ("15",
                                               this.id,
                                               "All Videos",
                                               "Videos",
                                               MediaItem.VIDEO_CLASS,
                                               http_server));

        // Now we know how many top-level containers we have
        this.child_count = this.containers.size;
    }

    public override Gee.List<MediaObject> get_children (uint     offset,
                                                        uint     max_count,
                                                        out uint child_count)
                                                        throws GLib.Error {
        child_count = this.containers.size;

        Gee.List<MediaObject> children = null;

        if (max_count == 0) {
            max_count = child_count;
        }

        uint stop = offset + max_count;

        stop = stop.clamp (0, child_count);
        children = this.containers.slice ((int) offset, (int) stop);

        if (children == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return children;
    }

    public override MediaObject find_object_by_id (string id)
                                                   throws GLib.Error {
        /* First try containers */
        MediaObject media_object = find_container_by_id (id);

        if (media_object == null) {
            /* Now try items */
            var container = get_item_parent (id);

            if (container != null)
                media_object = container.find_object_by_id (id);
        }

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return media_object;
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
}

