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
    private ArrayList<TrackerCategory> categories;

    public TrackerRootContainer (string title) {
        base.root (title, 0);

        this.categories = new ArrayList<TrackerCategory> ();
        this.categories.add
                        (new TrackerImageCategory ("16",
                                                   this,
                                                   "All Images"));
        this.categories.add
                        (new TrackerMusicCategory ("14",
                                                   this,
                                                   "All Music"));
        this.categories.add
                        (new TrackerVideoCategory ("15",
                                                   this,
                                                   "All Videos"));

        // Now we know how many top-level containers we have
        this.child_count = this.categories.size;
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        var children = this.categories.slice ((int) offset, (int) stop);

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
        MediaObject media_object = find_category_by_id (id);

        if (media_object == null) {
            /* Now try items */
            var category = get_item_category (id);

            if (category != null) {
                category.find_object (id, cancellable, callback);
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
    private TrackerCategory? find_category_by_id (string category_id) {
        TrackerCategory category;

        category = null;

        foreach (TrackerCategory tmp in this.categories)
            if (category_id == tmp.id) {
                category = tmp;

                break;
            }

        return category;
    }

    private TrackerCategory? get_item_category (string item_id) {
        TrackerCategory category = null;
        foreach (TrackerCategory tmp in this.categories) {
            if (tmp.is_thy_child (item_id)) {
                category = tmp;

                break;
            }
        }

        return category;
    }
}

