/*
 * Copyright (C) 2010 Nokia Corporation.
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

/**
 * Container providing a title-based hierarchy.
 *
 * Under each category container, add a container providing a title-based
 * hierarchy: One container for each unique starting character of all the titles
 * available for the contegory in question. Something like this:
 *
 * Music
 *   |
 *   |----> Genre
 *           |..
 *   ^
 *   |----> Titles
 *           |
 *           |---> A
 *                 |
 *                 |--> Alpha
 *                 |--> alright
 *           ^
 *           |---> B
 *                 |
 *                 |--> Bravo
 *                 |--> brave
 *                 |..
 *           ^
 *   ^       |..
 *   |..
 */
public class Rygel.LocalSearch.Titles : MetadataValues {
    private const string[] KEY_CHAIN = { "dc:title", null };

    public Titles (MediaContainer parent, ItemFactory item_factory) {
        base (parent.id + "Titles",
              parent,
              _("Titles"),
              item_factory,
              "dc:title");
    }

    // The parent class will only create a child container for each unique
    // title this method returns so we don't need to worry about multiple
    // containers being created for each letter.
    protected override string? create_title_for_value (string value) {
        var c = value.get_char_validated ();

        if (unlikely (c < 0)) {
            return null;
        }

        return c.to_string ().up ();
    }

    protected override string create_filter (string variable, string value) {
        var title = Query.escape_regex (this.create_title_for_value (value));

        return "regex(" + variable + ", \"^" + title + "\", \"i\")";
    }
}
