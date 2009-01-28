/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * Implementation of Tracker-based ContentDirectory service.
 */
public class Rygel.MediaTracker : ContentDirectory {
    /* FIXME: Make this a static if you know how to initize it */
    private ArrayList<TrackerContainer> containers;

    private SearchCriteriaParser search_parser;

    /* Pubic methods */
    public override void constructed () {
        // Chain-up to base first
        base.constructed ();

        this.containers = new ArrayList<TrackerContainer> ();
        this.containers.add
                        (new TrackerContainer ("16",
                                               this.root_container.id,
                                               "All Images",
                                               "Images",
                                               MediaItem.IMAGE_CLASS,
                                               this.http_server));
        this.containers.add
                        (new TrackerContainer ("14",
                                               this.root_container.id,
                                               "All Music",
                                               "Music",
                                               MediaItem.MUSIC_CLASS,
                                               this.http_server));
        this.containers.add
                        (new TrackerContainer ("15",
                                               this.root_container.id,
                                               "All Videos",
                                               "Videos",
                                               MediaItem.VIDEO_CLASS,
                                               this.http_server));

        // Now we know how many top-level containers we have
        this.root_container.child_count = this.containers.size;

        this.search_parser = new SearchCriteriaParser ();
    }

    public override ArrayList<MediaObject> get_children (
                                                 string   container_id,
                                                 uint     offset,
                                                 uint     max_count,
                                                 out uint child_count)
                                                 throws GLib.Error {
        var container = this.find_container_by_id (container_id);
        if (container == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return container.get_children_from_db (offset,
                                               max_count,
                                               out child_count);
    }

    public override MediaObject find_object_by_id (string object_id)
                                                   throws GLib.Error {
        /* First try containers */
        MediaObject media_object = find_container_by_id (object_id);

        if (media_object == null) {
            /* Now try items */
            var container = get_item_parent (object_id);

            if (container != null)
                media_object = container.get_item_from_db (object_id);
        }

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return media_object;
    }

    public override ArrayList<MediaObject> get_root_children (
                                                 uint     offset,
                                                 uint     max_count,
                                                 out uint child_count)
                                                 throws GLib.Error {
        child_count = this.containers.size;

        Gee.List<MediaObject> children = null;

        if (max_count == 0 && offset == 0) {
            children = this.containers;
        } else {
            uint stop = offset + max_count;

            stop = stop.clamp (0, child_count);
            children = this.containers.slice ((int) offset, (int) stop);
        }

        if (children == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return (ArrayList<MediaObject>) children;
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

