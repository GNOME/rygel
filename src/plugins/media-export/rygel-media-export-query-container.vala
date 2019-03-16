/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
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
using GUPnP;

internal abstract class Rygel.MediaExport.QueryContainer : DBContainer {
    // public static members
    public const string PREFIX = "virtual-container:";
    public const string ITEM_PREFIX = "virtual-id:";

    // public members
    public SearchExpression expression { get; construct set; }

    // constructors
    protected QueryContainer (SearchExpression expression,
                              string           id,
                              string           name) {
        Object (id : id,
                parent : null,
                title : name,
                child_count : 0,
                expression : expression);
    }

    // public methods
    public async override MediaObjects? search (SearchExpression? expression,
                                                uint              offset,
                                                uint              max_count,
                                                string            sort_criteria,
                                                Cancellable?      cancellable,
                                                out uint          total_matches)
                                                throws GLib.Error {
        debug ("Running search %s on query container %s",
               expression == null ? "null" : expression.to_string (),
               this.id);
        // Override DBContainer search to always use fall-back search.
        return yield this.simple_search (expression,
                                         offset,
                                         max_count,
                                         sort_criteria,
                                         cancellable,
                                         out total_matches);
    }

}
