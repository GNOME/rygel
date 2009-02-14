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

    public TrackerRootContainer (string title) {
        base.root (title, 0);

        this.containers = new ArrayList<TrackerContainer> ();
        this.containers.add
                        (new TrackerImageContainer ("16",
                                                    this.id,
                                                    "All Images"));
        this.containers.add
                        (new TrackerMusicContainer ("14",
                                                    this.id,
                                                    "All Music"));
        this.containers.add
                        (new TrackerVideoContainer ("15",
                                                    this.id,
                                                    "All Videos"));

        // Now we know how many top-level containers we have
        this.child_count = this.containers.size;
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        var children = this.containers.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>> (
                                        this,
                                        callback);
        res.data = children;
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
        /* First try containers */
        MediaObject media_object = find_container_by_id (id);

        if (media_object == null) {
            /* Now try items */
            var container = get_item_parent (id);

            if (container != null) {
                container.find_object (id, cancellable, callback);
                return;
            }
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

    private TrackerContainer? get_item_parent (string item_id) {
        TrackerContainer container = null;
        foreach (TrackerContainer tmp in this.containers) {
            if (tmp.is_thy_child (item_id)) {
                container = tmp;

                break;
            }
        }

        return container;
    }
}

