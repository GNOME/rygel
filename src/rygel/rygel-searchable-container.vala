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

public interface Rygel.SearchableContainer : MediaContainer {
    /**
     * Recursively searches for all media objects that satisfy the given search
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
    public abstract async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                out uint          total_matches,
                                                Cancellable?      cancellable)
                                                throws Error;

    /**
     * Utility method that retrieves all children and recursively searches for
     * all media objects that satisfy the given search expression in this
     * container.
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
    public async MediaObjects? simple_search (SearchExpression? expression,
                                              uint              offset,
                                              uint              max_count,
                                              out uint          total_matches,
                                              Cancellable?      cancellable)
                                              throws Error {
        var result = new MediaObjects ();

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

        // First add relavant children
        foreach (var child in children) {
            if (expression == null || expression.satisfied_by (child)) {
                result.add (child);
            }

            if (limit > 0 && result.size >= limit) {
                break;
            }
        }

        if (limit == 0 || result.size < limit) {
            // Then search in the children
            var child_limit = (limit == 0)? 0: limit - result.size;

            var child_results = yield this.search_in_children (expression,
                                                               children,
                                                               child_limit,
                                                               cancellable);
            result.add_all (child_results);
        }

        // See if we need to slice the results
        if (result.size > 0 && limit > 0) {
            uint start;
            uint stop;

            start = offset.clamp (0, result.size - 1);

            if (max_count != 0 && start + max_count <= result.size) {
                stop = start + max_count;
            } else {
                stop = result.size;
            }

            // Since we limited our search, we don't know how many objects
            // actually satisfy the give search expression
            total_matches = 0;

            return result.slice ((int) start, (int) stop) as MediaObjects;
        } else {
            total_matches = result.size;

            return result;
        }
    }

    /**
     * Recursively searches for media object with the given id in this
     * container.
     *
     * @param id ID of the media object to search for
     * @param cancellable optional cancellable for this operation
     * @param callback function to call when result is ready
     *
     * return the found media object.
     */
    public async MediaObject? find_object (string       id,
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

    private async MediaObjects search_in_children (SearchExpression expression,
                                                   MediaObjects     children,
                                                   uint             limit,
                                                   Cancellable?     cancellable)
                                                   throws Error {
        var result = new MediaObjects ();

        foreach (var child in children) {
            if (child is SearchableContainer) {
                var container = child as SearchableContainer;
                uint tmp;

                var child_result = yield container.search (expression,
                                                           0,
                                                           limit,
                                                           out tmp,
                                                           cancellable);

                result.add_all (child_result);
            }

            if (limit > 0 && result.size >= limit) {
                break;
            }
        }

        return result;
    }
}
