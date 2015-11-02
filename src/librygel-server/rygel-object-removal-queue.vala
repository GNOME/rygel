/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using Gee;

/**
 * Queues objects for removal after 35 seconds or immediately.
 *
 * The 35s timeout comes from the DLNA documentation.
 */
internal class Rygel.ObjectRemovalQueue: GLib.Object {
    private const uint TIMEOUT = 35;

    private static ObjectRemovalQueue removal_queue;

    private HashMap<string,uint> object_timeouts;

    public static ObjectRemovalQueue get_default () {
        if (unlikely (removal_queue == null)) {
            removal_queue = new ObjectRemovalQueue ();
        }

        return removal_queue;
    }

    public void queue (MediaObject object, Cancellable? cancellable) {
        if (object.parent_ref == null) {
            object.parent_ref = object.parent;
        }

        var timeout = Timeout.add_seconds (TIMEOUT, () => {
            debug ("Timeout on temporary object '%s'.", object.id);
            this.remove_now.begin (object, cancellable);

            return false;
        });

        object_timeouts.set (object.id, timeout);
    }

    public bool dequeue (MediaObject object) {
        uint timeout;

        if (object_timeouts.unset (object.id, out timeout)) {
            Source.remove (timeout);

            return true;
        } else {
            return false;
        }
    }

    public async void remove_now (MediaObject object, Cancellable? cancellable) {
        object_timeouts.unset (object.id);

        var parent = object.parent as WritableContainer;

        try {
            if (object is MediaItem) {
                yield parent.remove_item (object.id, cancellable);
            } else {
                yield parent.remove_container (object.id, cancellable);
            }

            debug ("Auto-destroyed object '%s'!", object.id);
        } catch (Error err) {
            warning (/*_*/("Failed to auto-destroy temporary object '%s': %s"),
                     object.id,
                     err.message);
        }
    }

    private ObjectRemovalQueue () {
        object_timeouts = new HashMap<string,uint> ();
    }
}
