/*
 * Copyright (C) 2011 Jens Georg <mail@jensge.org>.
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

internal class Rygel.MediaExport.LeafQueryContainer : QueryContainer {
    public LeafQueryContainer (SearchExpression expression,
                               string           id,
                               string           name) {
        Object (id : id,
                title : name,
                parent : null,
                child_count : 0,
                expression : expression);
    }

    public override async MediaObjects? get_children
                                        (uint         offset,
                                         uint         max_count,
                                         string       sort_criteria,
                                         Cancellable? cancellable)
                                         throws GLib.Error {
        uint total_matches;
        var children = this.media_db.get_objects_by_search_expression
                                         (this.expression,
                                          "0",
                                          sort_criteria,
                                          offset,
                                          max_count,
                                          out total_matches);
        foreach (var child in children) {
            var container_id = QueryContainer.ITEM_PREFIX +
                               this.id.replace (QueryContainer.PREFIX, "");
            child.ref_id = child.id;
            child.id = container_id + ":" + child.ref_id;
            child.parent_ref = this;
        }

        return children;
    }

    public override int count_children () {
        try {
            return (int) this.media_db.get_object_count_by_search_expression
                                        (this.expression, null);
        } catch (Error error) {
            warning (_("Failed to get child count of query container: %s"),
                     error.message);

            return 0;
        }
    }
}
