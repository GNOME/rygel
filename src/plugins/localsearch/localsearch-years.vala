/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
 * Container listing content hierarchy by year of creation.
 */
public class Rygel.LocalSearch.Years : MetadataValues {
    public Years (MediaContainer parent, ItemFactory item_factory) {
        base (parent.id + "Year",
              parent,
              _("Year"),
              item_factory,
              "date");
    }

    protected override string? create_title_for_value (string value) {
        return value.substring (0, 4);
    }

    protected override string create_filter (string variable, string value) {
        var year = this.create_title_for_value (value);
        var next_year = (int.parse (year) + 1).to_string ();

        year += "-01-01T00:00:00Z";
        next_year += "-01-01T00:00:00Z";

        return variable + " > \"" + year + "\"^^xsd:dateTime && " +
               variable + " < \"" + next_year + "\"^^xsd:dateTime";
    }
}
