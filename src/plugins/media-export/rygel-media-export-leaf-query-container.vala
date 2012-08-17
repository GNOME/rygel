/*
 * Copyright (C) 2011 Jens Georg <mail@jensge.org>.
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

internal class Rygel.MediaExport.LeafQueryContainer : QueryContainer {
    public LeafQueryContainer (MediaCache       cache,
                               SearchExpression expression,
                               string           id,
                               string           name) {
        base (cache, expression, id, name);
    }

    public override async MediaObjects? get_children
                                        (uint         offset,
                                         uint         max_count,
                                         string       sort_criteria,
                                         Cancellable? cancellable)
                                         throws GLib.Error {
        uint total_matches;
        var children = yield this.search (null,
                                          offset,
                                          max_count,
                                          out total_matches,
                                          sort_criteria,
                                          cancellable);
        foreach (var child in children) {
            child.parent = this;
        }

        return children;
    }

    protected override int count_children () throws Error {
        return (int) this.media_db.get_object_count_by_search_expression
                                        (this.expression, null);
    }
}
