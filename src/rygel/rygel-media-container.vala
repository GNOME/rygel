/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
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

using GUPnP;

/**
 * Represents a container (folder) for media items and containers. Provides
 * basic serialization (to DIDLLiteWriter) implementation. Deriving classes
 * are supposed to provide working implementations of get_children and
 * find_object.
 */
public abstract class Rygel.MediaContainer : MediaObject {
    /**
     * container_updated signal that is emitted if a child container under the
     * tree of this container gets updated.
     *
     * @param container the container that just got updated.
     */
    public signal void container_updated (MediaContainer container);

    public uint child_count;
    public uint32 update_id;

    public MediaContainer (string          id,
                           MediaContainer? parent,
                           string          title,
                           uint            child_count) {
        this.id = id;
        this.parent = parent;
        this.title = title;
        this.child_count = child_count;
        this.update_id = 0;

        this.container_updated += on_container_updated;
    }

    public MediaContainer.root (string title,
                                uint   child_count) {
        this ("0", null, title, child_count);
    }

    /**
     * Fetches the list of media objects directly under this container and
     * calls callback once the result is ready.
     *
     * @param offet zero-based index of the first item to return
     * @param max_count maximum number of objects to return
     * @param cancellable optional cancellable for this operation
     * @param callback function to call when result is ready
     */
    public abstract void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback);

    /**
     * Finishes the operation started by #get_children.
     *
     * @param res an AsyncResult
     *
     * return A list of media objects.
     */
    public abstract Gee.List<MediaObject>? get_children_finish (
                                                    AsyncResult res)
                                                    throws Error;

   /**
    * Recursively searches for media object with the given id in this
    * container and calls callback when the result is available.
    *
    * @param id ID of the media object to search for
    * @param cancellable optional cancellable for this operation
    * @param callback function to call when result is ready
    *
    */
    public abstract void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback);

    /**
     * Finishes the search operation started by #find_object.
     *
     * @param res an AsyncResult
     *
     * return the found media object.
     */
    public abstract MediaObject? find_object_finish (AsyncResult res)
                                                     throws Error;

    /**
     * Method to be be called each time this container is updated (metadata
     * changes for this container, items under it gets removed/added or their
     * metadata changes etc).
     *
     * @param container the container that just got updated.
     */
    public void updated () {
        this.update_id++;

        // Emit the signal that will start the bump-up process for this event.
        this.container_updated (this);
    }

    /**
     * handler for container_updated signal on this container. We only forward
     * it to the parent, hoping someone will get it from the root container
     * and act upon it.
     *
     * @param container the container that emitted the signal
     * @param updated_container the container that just got updated
     */
    private void on_container_updated (MediaContainer container,
                                       MediaContainer updated_container) {
        if (this.parent != null) {
            this.parent.container_updated (updated_container);
        }
    }
}

