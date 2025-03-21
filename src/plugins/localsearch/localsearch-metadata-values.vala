/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
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
using Tsparql;

/**
 * Container listing possible values of a particuler LocalSearch metadata key.
 * The key needs to be single-valued.
 */
public abstract class Rygel.LocalSearch.MetadataValues : MetadataContainer {
    private string property;

    protected MetadataValues (string         id,
                              MediaContainer parent,
                              string         title,
                              ItemFactory    item_factory,
                              string         property,
                              string?        child_class = null) {
        base (id, parent, title, item_factory, child_class);

        this.property = property;

        this.triplets = new QueryTriplets ();

        this.triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                             "a",
                                             this.item_factory.category));
        this.triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                             "nie:isStoredAs",
                                             SelectionQuery.STORAGE_VARIABLE));
        this.fetch_metadata_values.begin ();
    }

    protected override SelectionQuery create_query () {
        var property_map = UPnPPropertyMap.get_property_map ();
        var selected = new ArrayList<string> ();
        selected.add ("DISTINCT " +
                      property_map[this.property] +
                      " AS ?x");

        var q = new SelectionQuery (selected,
                                    triplets,
                                    null,
                                    this.item_factory.graph,
                                    "?x");
        return q;
    }

    protected override SearchContainer create_container (string id,
                                                         string title,
                                                         string value) {
        // The child container can use the same triplets we used in our
        // query.
        var child_triplets = new QueryTriplets.clone (this.triplets);

        // However we constrain the object of our last triplet.
        var filters = new ArrayList<string> ();
        var property_map = UPnPPropertyMap.get_property_map ();
        var property = property_map[this.property];
        var filter = this.create_filter (property, value);
        filters.add (filter);

        var child = new SearchContainer (id,
                                         this,
                                         title,
                                         this.item_factory,
                                         child_triplets,
                                         filters);
        if (this.property == "upnp:album") {
            child.sort_criteria = MediaContainer.ALBUM_SORT_CRITERIA;
        }

        return child;
    }
}
