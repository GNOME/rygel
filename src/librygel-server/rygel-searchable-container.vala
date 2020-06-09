/*
 * Copyright (C) 2008,2010 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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

using GUPnP;
using Gee;

/**
 * The base class for searchable containers.
 *
 * Classes that implement this interface can, for instance:
 *
 *  # Allow backends to implement a UPnP Search call using native searching (such as SQL or SPARQL queries).
 *  # Implement searching via the naïve default implementation provided by rygel_searchable_container_simple_search(), which does a recursive tree walk.
 *
 * The search_classes property lists what information this container may be searched
 * for. It is mapped to upnp:searchClass (with includeDerived assumed to be false),
 */
public interface Rygel.SearchableContainer : MediaContainer {
    public abstract ArrayList<string> search_classes { get; set; }

    /**
     * Recursively searches for all media objects that satisfy the given search
     * expression in this container.
     *
     * @param expression the search expression or null for wildcard
     * @param offset zero-based index of the first object to return
     * @param total_matches sets it to the actual number of objects that satisfy
     * @param cancellable optional cancellable for this operation.
     * @param max_count maximum number of objects to return
     *
     * @return A list of matching media objects or null if no object matched.
     */
    public abstract async MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                string            sort_criteria,
                                                Cancellable?      cancellable,
                                                out uint          total_matches)
                                                throws Error;

    /**
     * Utility method that retrieves all children and recursively searches for
     * all media objects that satisfy the given search expression in this
     * container.
     *
     * @param expression the search expression or `null` for wildcard
     * @param offset zero-based index of the first object to return
     * @param max_count maximum number of objects to return
     * @param total_matches sets it to the actual number of objects that satisfy
     *                      the given search expression. If it is not possible
     *                      to compute this value (in a timely mannger), it is
     *                      set to '0'.
     * @param cancellable optional cancellable for this operation
     *
     * @return A list of media objects.
     */
    public async MediaObjects? simple_search (SearchExpression? expression,
                                              uint              offset,
                                              uint              max_count,
                                              string            sort_criteria,
                                              Cancellable?      cancellable,
                                              out uint          total_matches)
                                              throws Error {
        var result = new MediaObjects ();

        int count = this.child_count;
        this.check_search_expression (expression);

        if (this.create_mode_enabled) {
            count = this.all_child_count;
        }

        var children = yield this.get_children (0,
                                                count,
                                                sort_criteria,
                                                cancellable);

        // The maximum number of results we need to be able to slice-out
        // the needed portion from it.
        uint limit;
        if (max_count > 0) {
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
                                                               sort_criteria,
                                                               cancellable);
            result.add_all (child_results);
        }

        // Since we limited our search, we don't know how many objects
        // actually satisfy the give search expression
        if (max_count > 0) {
            total_matches = 0;
        } else {
            total_matches = result.size;
        }

        if (offset >= result.size) {
            return new MediaObjects ();
        }

        // See if we need to slice the results
        if (result.size > 0 && (max_count > 0 || offset > 0)) {
            uint stop;

            if (max_count != 0 && offset + max_count <= result.size) {
                stop = offset + max_count;
            } else {
                stop = result.size;
            }

            return result.slice ((int) offset, (int) stop) as MediaObjects;
        }

        return result;
    }

    /**
     * Recursively searches for media object with the given id in this
     * container.
     *
     * @param id ID of the media object to search for
     * @param cancellable optional cancellable for this operation
     * @param callback function to call when result is ready
     *
     * @return the found media object.
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
                                         "",
                                         cancellable,
                                         out total_matches);
        if (results.size > 0) {
            return results[0];
        } else {
            return null;
        }
    }

    private async MediaObjects search_in_children
                                        (SearchExpression? expression,
                                         MediaObjects      children,
                                         uint              limit,
                                         string            sort_criteria,
                                         Cancellable?      cancellable)
                                        throws Error {
        var result = new MediaObjects ();

        foreach (var child in children) {
            if (child is SearchableContainer) {
                var container = child as SearchableContainer;
                uint tmp;

                var child_result = yield container.search (expression,
                                                           0,
                                                           limit,
                                                           sort_criteria,
                                                           cancellable,
                                                           out tmp);

                result.add_all (child_result);
            }

            if (limit > 0 && result.size >= limit) {
                break;
            }
        }

        return result;
    }

    internal void serialize_search_parameters
                                        (DIDLLiteContainer didl_container) {
        foreach (var search_class in this.search_classes) {
            didl_container.add_search_class (search_class);
        }
    }
}
