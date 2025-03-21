/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008,2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

/**
 * A container listing all newly (<3 days) added items.
 */
public class Rygel.LocalSearch.New : Rygel.LocalSearch.SearchContainer {
    private const string ADDED_PREDICATE = "nrl:added";
    private const string ADDED_VARIABLE = "?added";

    public New (MediaContainer parent, ItemFactory item_factory) {
        var triplets = new QueryTriplets ();

        triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                        "a",
                                        item_factory.category));
        triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                        ADDED_PREDICATE,
                                        ADDED_VARIABLE));

        var now = new DateTime.now_utc ();
        now = now.add_days (-3);
        var three_days_ago = "%sZ".printf (now.format ("%Y-%m-%dT%H:%M:%S"));

        var filters = new ArrayList<string> ();
        filters.add (ADDED_VARIABLE + " > \"" + three_days_ago + "\"^^xsd:dateTime");

        base (parent.id + "New",
              parent,
              "New",
              item_factory,
              triplets,
              filters);
    }
}
