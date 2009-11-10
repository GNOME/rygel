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
using Gee;

/**
 * Represents a container (folder) for media items and containers. Provides
 * basic serialization (to DIDLLiteWriter) implementation. Deriving classes
 * are supposed to provide working implementations of get_children.
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
        this.upnp_class = "object.container.storageFolder";

        this.container_updated += on_container_updated;
    }

    public MediaContainer.root (string title,
                                uint   child_count) {
        this ("0", null, title, child_count);
    }

    /**
     * Fetches the list of media objects directly under this container.
     *
     * @param offet zero-based index of the first item to return
     * @param max_count maximum number of objects to return
     * @param cancellable optional cancellable for this operation
     *
     * return A list of media objects.
     */
    public async abstract Gee.List<MediaObject>? get_children (
                                        uint               offset,
                                        uint               max_count,
                                        Cancellable?       cancellable)
                                        throws Error;

   /**
    * Recursively searches for media object with the given id in this container.
    *
    * @param id ID of the media object to search for
    * @param cancellable optional cancellable for this operation
    * @param callback function to call when result is ready
    *
    * return the found media object.
    */
    public async virtual MediaObject? find_object (string       id,
                                                   Cancellable? cancellable)
                                                   throws Error {
        var expression = new RelationalExpression ();
        expression.op = SearchCriteriaOp.EQ;
        expression.operand1 = "@id";
        expression.operand2 = id;

        uint total_matches;
        var results = yield this.search (expression,
                                         0,
                                         1,
                                         out total_matches,
                                         cancellable);
        if (results.size > 0) {
            return results[0];
        } else {
            return null;
        }
    }

    /**
     * Recursively searches for all media objects the satisfy the given search
     * expression in this container.
     *
     * @param expression the search expression or `null` for wildcard
     * @param offet zero-based index of the first object to return
     * @param max_count maximum number of objects to return
     * @param total_matches sets it to the actual number of objects that satisfy
     *                      the given search expression. If it is not possible
     *                      to compute this value (in a timely mannger), it is
     *                      set to '0'.
     * @param cancellable optional cancellable for this operation
     *
     * return A list of media objects.
     */
    public virtual async Gee.List<MediaObject>? search (
                                        SearchExpression   expression,
                                        uint               offset,
                                        uint               max_count,
                                        out uint           total_matches,
                                        Cancellable?       cancellable)
                                        throws Error {
        var result = new ArrayList<MediaObject> ();

        var children = yield this.get_children (0,
                                                this.child_count,
                                                cancellable);

        // The maximum number of results we need to be able to slice-out
        // the needed portion from it.
        uint limit;
        if (offset > 0 || max_count > 0) {
            limit = offset + max_count;
        } else {
            limit = 0; // No limits on searches
        }

        foreach (var child in children) {
            if (child is MediaContainer) {
                // First search inside the child container
                var container = child as MediaContainer;
                uint tmp;

                var child_result = yield container.search (expression,
                                                           0,
                                                           limit,
                                                           out tmp,
                                                           cancellable);

                result.add_all (child_result);
            }

            // Then check if child itself satisfies search criteria
            if (expression == null || expression.satisfied_by (child)) {
                result.add (child);
            }

            if (limit > 0 && result.size >= limit) {
                break;
            }
        }

        // See if we need to slice the results
        if (result.size > 0 && limit > 0) {
            uint start;
            uint stop;

            start = offset.clamp (0, result.size - 1);

            if (max_count != 0) {
                stop = start + max_count;
            } else {
                stop = result.size - 1;
            }

            // Since we limited our search, we don't know how many objects
            // actually satisfy the give search expression
            total_matches = 0;

            return result.slice ((int) start, (int) stop);
        } else {
            total_matches = result.size;

            return result;
        }
    }

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

