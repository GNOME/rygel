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

internal class Rygel.MediaExport.NodeQueryContainer : QueryContainer {
    public string template { private get; construct; }
    public string attribute { private get; construct; }

    public NodeQueryContainer (SearchExpression expression,
                               string           id,
                               string           name,
                               string           template,
                               string           attribute) {
        Object (id : id,
                title : name,
                parent : null,
                child_count : 0,
                expression : expression,
                template : template,
                attribute : attribute);
    }

    // MediaContainer overrides

    public override async MediaObjects? get_children
                                        (uint         offset,
                                         uint         max_count,
                                         string       sort_criteria,
                                         Cancellable? cancellable)
                                         throws GLib.Error {
        var children = new MediaObjects ();
        var factory = QueryContainerFactory.get_default ();

        var data = this.media_db.get_object_attribute_by_search_expression
                                        (this.attribute,
                                         this.expression,
                                         sort_criteria,
                                         offset,
                                         max_count,
                                         this.add_all_container ());

        foreach (var meta_data in data) {
            string id;
            MediaContainer container;
            if (meta_data == "all_place_holder") {
                id = this.template.replace (",upnp:album,%s", "");
                container = factory.create_from_description_id (id, _("All"));
            } else {
                id = Uri.escape_string (meta_data, "", true);
                // template contains URL escaped text. This means it might
                // contain '%' chars which will makes sprintf crash
                id = this.template.replace ("%s", id);
                container = factory.create_from_description_id (id,
                                                                meta_data);
            }
            container.parent = this;
            children.add (container);
        }

        return children;
    }

    // DBContainer overrides

    public override int count_children () {
        try {
            var data = this.media_db.get_object_attribute_by_search_expression
                                        (this.attribute,
                                         this.expression,
                                         "+dc:title",
                                         0,
                                         -1,
                                         this.add_all_container ());

            return data.size;
        } catch (Error error) {
            warning (_("Failed to get child count: %s"), error.message);

            return 0;
        }
    }

    private bool add_all_container () {
        return false;
    }
}
