/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using Gee;

/**
 * Queues items for removal after 35 seconds or immediately.
 */
internal class Rygel.ItemRemovalQueue: GLib.Object {
    private const uint TIMEOUT = 35;

    private static ItemRemovalQueue removal_queue;

    private HashMap<string,uint> item_timeouts;

    public static ItemRemovalQueue get_default () {
        if (unlikely (removal_queue == null)) {
            removal_queue = new ItemRemovalQueue ();
        }

        return removal_queue;
    }

    public void queue (MediaItem item, Cancellable? cancellable) {
        if (item.parent_ref == null) {
            item.parent_ref = item.parent;
        }

        var timeout = Timeout.add_seconds (TIMEOUT, () => {
            debug ("Timeout on temporary item '%s'.", item.id);
            this.remove_now.begin (item, cancellable);

            return false;
        });

        item_timeouts.set (item.id, timeout);
    }

    public bool dequeue (MediaItem item) {
        uint timeout;

        if (item_timeouts.unset (item.id, out timeout)) {
            Source.remove (timeout);

            return true;
        } else {
            return false;
        }
    }

    public async void remove_now (MediaItem item, Cancellable? cancellable) {
        item_timeouts.unset (item.id);

        var parent = item.parent as WritableContainer;

        try {
            yield parent.remove_item (item.id, cancellable);

            debug ("Auto-destroyed item '%s'!", item.id);
        } catch (Error err) {
            warning ("Failed to auto-destroy temporary item '%s': %s",
                     item.id,
                     err.message);
        }
    }

    private ItemRemovalQueue () {
        item_timeouts = new HashMap<string,uint> ();
    }
}
