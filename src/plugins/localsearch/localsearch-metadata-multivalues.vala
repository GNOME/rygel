/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
 *         Jens Georg <mail@jensge.org>
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
 * Container listing possible values of a particuler LocalSearch metadata key.
 * This class is used for multivalue properties such as nao:Tag (via
 * nao:hasTag)
 */
public abstract class Rygel.LocalSearch.MetadataMultiValues : MetadataContainer {
    public string[] key_chain;

    protected MetadataMultiValues (string         id,
                                   MediaContainer parent,
                                   string         title,
                                   ItemFactory    item_factory,
                                   string[]       key_chain,
                                   string?        child_class = null) {
        base (id, parent, title, item_factory, child_class);

        this.key_chain = key_chain;

        this.fetch_metadata_values.begin ();
    }

    protected override SelectionQuery create_query () {
        this.triplets = new QueryTriplets ();

        this.triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                             "a",
                                             this.item_factory.category));
        this.triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                             "nie:isStoredAs",
                                             SelectionQuery.STORAGE_VARIABLE));

        // All variables used in the query
        var num_keys = this.key_chain.length - 1;
        var variables = new string[num_keys];
        for (int i = 0; i < num_keys; i++) {
            variables[i] = "?" + key_chain[i].replace (":", "_");

            string subject;
            if (i == 0) {
                subject = SelectionQuery.ITEM_VARIABLE;
            } else {
                subject = variables[i - 1];
            }

            this.triplets.add (new QueryTriplet (subject,
                                                 this.key_chain[i],
                                                 variables[i]));
        }

        // Variables to select from query
        var selected = new ArrayList<string> ();
        // Last variable is the only thing we are interested in the result
        var last_variable = variables[num_keys - 1];
        selected.add ("DISTINCT " + last_variable);

        return new SelectionQuery (selected, triplets, null, this.item_factory.graph, last_variable);
    }

    protected override SearchContainer create_container (string id,
                                                         string title,
                                                         string value) {

        // The child container can use the same triplets we used in our
        // query.
        var child_triplets = new QueryTriplets.clone (triplets);

        // However we constrain the object of our last triplet.
        var filters = new ArrayList<string> ();
        var filter = this.create_filter (child_triplets.last ().obj, value);
        filters.add (filter);

        return new SearchContainer (id,
                                    this,
                                    title,
                                    this.item_factory,
                                    child_triplets,
                                    filters);
    }
}
