/*
 * Copyright (C) 2012,2013 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * The base class for containers that provide automatic change tracking.
 *
 * Derived classes should implement the add_child() and remove_child()
 * virtual functions to keep track of child items and child containers.
 *
 * Rygel server plugins (See #RygelMediaServer) may then call
 * rygel_trackable_container_add_child_tracked() and
 * rygel_trackable_container_remove_child_tracked() to add and remove
 * items, which will then cause the #RygelContainer::container_updated signal
 * to be emitted.
 */
public interface Rygel.TrackableContainer : Rygel.MediaContainer {
    public async void clear () {
        try {
            var children = yield this.get_children (0,
                                                    -1,
                                                    this.sort_criteria,
                                                    null);

            if (children == null) {
                return;
            }

            foreach (var child in children) {
                yield this.remove_child_tracked (child);
            }
        } catch (Error error) {
            warning (/*_*/("Failed to clear trackable container %s: %s"),
                     id,
                     error.message);
        }
    }

    /**
     * Derived classes should implement this, keeping track
     * of the child item or child container.
     * See the remove_child() virtual function.
     */
    protected abstract async void add_child (MediaObject object);
    protected signal void child_added (MediaObject object);
    protected signal void child_removed (MediaObject object);

    /**
     * Add a child object, emitting the #RygelContainer::container_updated signal
     * with the object.
     * @see rygel_trackable_object_remove_child_tracked()
     *
     * @param object The child item or child container to be added.
     */
    public async void add_child_tracked (MediaObject object) {
        yield this.add_child (object);

        this.updated (object, ObjectEventType.ADDED);
        this.updated ();
        if (object is TrackableContainer) {
            var trackable = object as TrackableContainer;

            // Release the events that might have accumulated
            trackable.thaw_events ();
        }
        this.child_added (object);
    }

    /**
     * Derived classes should implement this, removing the
     * child item or child container from its set of objects.
     * See the add_child() virtual function.
     */
    protected abstract async void remove_child (MediaObject object);

    /**
     * Add a child object, emitting the #RygelContainer::container_updated signal
     * with the object.
     * @see rygel_trackable_object_add_child_tracked()
     *
     * @param object The child item or child container to be added.
     */
    public async void remove_child_tracked (MediaObject object) {
        // We need to descend into this to get the proper events
        if (object is TrackableContainer) {
            var trackable = object as TrackableContainer;
            yield trackable.clear ();
        }

        yield this.remove_child (object);

        this.updated (object, ObjectEventType.DELETED);
        this.total_deleted_child_count++;

        // FIXME: Check if modification of child_count should lead to
        // LastChange event.
        this.updated ();
        this.child_removed (object);
    }

    /**
     * Used to query the (persisted) service reset token from the plug-in.
     *
     * If a plugin implements PLUGIN_CAPABILITIES_TRACK_CHANGES, it should
     * persist the ServiceResetToken. To do this override this virtual
     * function in the root container implementation and provide the persisted
     * version.
     */
    public virtual string get_service_reset_token () {
        return Uuid.string_random ();
    }

    /**
     * Set a new service reset token.
     *
     * If the service reset procedure has to be performed, the content
     * directory service will set the new service reset token.
     *
     * @param token the new service reset token.
     */
    public virtual void set_service_reset_token (string token) {}

    /**
     * Query the current system update ID,
     * used for the UPnP GetSystemUpdateID implementation.
     *
     * This should be overriden by the root container of the back-end
     * implementation. This will only be called once, at service startup, 
     * to discover the cached system Update ID, if any, that was known
     * when the service last shut down.
     *
     * Derived classes may need to delay part of their initialization
     * until this function has been called, doing that initialization in
     * the function override. That can prevent other parts of their 
     * implementation from changing the cached System Update ID before
     * it has been provided.
     *
     * @return the current SystemUpdateID as persisted by the back-end.
     */
    public virtual uint32 get_system_update_id () { return 0; }

    private void thaw_events () {
        // Forward events.
    }
}
