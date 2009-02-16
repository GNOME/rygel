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
}

