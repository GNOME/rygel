/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
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
using GUPnP;

internal abstract class Rygel.MediaExport.QueryContainer : DBContainer {
    // public static members
    public static const string PREFIX = "virtual-container:";

    // protected members
    protected SearchExpression expression;

    // constructors
    public QueryContainer (MediaCache       cache,
                           SearchExpression expression,
                           string           id,
                           string           name) {
        base (cache, id, name);

        this.expression = expression;

        try {
            this.child_count = this.count_children ();
        } catch (Error error) {
            this.child_count = 0;
        }
    }

    // public methods
    public async override MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                out uint          total_matches,
                                                string            sort_criteria,
                                                Cancellable?      cancellable)
                                                throws GLib.Error {
        MediaObjects children = null;

        SearchExpression combined_expression;

        if (expression == null) {
            combined_expression = this.expression;
        } else {
            var local_expression = new LogicalExpression ();
            local_expression.operand1 = this.expression;
            local_expression.op = LogicalOperator.AND;
            local_expression.operand2 = expression;
            combined_expression = local_expression;
        }

        try {
            children = this.media_db.get_objects_by_search_expression
                                        (combined_expression,
                                         null,
                                         sort_criteria,
                                         offset,
                                         max_count,
                                         out total_matches);
        } catch (MediaCacheError error) {
            if (error is MediaCacheError.UNSUPPORTED_SEARCH) {
                children = new MediaObjects ();
                total_matches = 0;
            } else {
                throw error;
            }
        }

        return children;
    }

    protected abstract int count_children () throws Error;
}
