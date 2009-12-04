/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
 * Container listing content hierarchy by year of creation.
 */
public class Rygel.TrackerYears : Rygel.TrackerMetadataValues {
    private const string[] KEY_CHAIN = { "nie:contentCreated", null };

    public TrackerYears (string             id,
                         MediaContainer     parent,
                         TrackerItemFactory item_factory) {
        base (id,
              parent,
              "Year",
              item_factory,
              KEY_CHAIN,
              year_id_func,
              year_id_func,
              year_filter_func);
    }

    private static string year_id_func (string value) {
        return value.ndup (4);
    }

    private static string year_filter_func (string variable, string value) {
        var year = year_id_func (value);
        var next_year = (year.to_int () + 1).to_string ();

        year += "-01-01T00:00:00Z";
        next_year += "-01-01T00:00:00Z";

        return variable + " > \"" + year + "\" && " +
               variable + " < \"" + next_year + "\"";
    }
}

