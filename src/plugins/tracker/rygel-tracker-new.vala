/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008,2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

/**
 * A container listing all newly (<3 days) added items.
 */
public class Rygel.Tracker.New : Rygel.Tracker.SearchContainer {
    private const string ADDED_PREDICATE = "tracker:added";
    private const string ADDED_VARIABLE = "?added";
    private const long THREE_DAYS_AS_SEC = 259200;

    public New (MediaContainer parent, ItemFactory item_factory) {
        var triplets = new QueryTriplets ();

        triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                        "a",
                                        item_factory.category));
        triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                        ADDED_PREDICATE,
                                        ADDED_VARIABLE));

        var time = TimeVal ();
        time.tv_sec -= THREE_DAYS_AS_SEC;

        var filters = new ArrayList<string> ();
        filters.add (ADDED_VARIABLE + " > \"" + time.to_iso8601 () + "\"");

        base (parent.id + "New",
              parent,
              "New",
              item_factory,
              triplets,
              filters);
    }
}
