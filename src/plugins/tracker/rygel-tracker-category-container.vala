/*
 * Copyright (C) 2010 Nokia Corporation.
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
 * Container listing content hierarchy for a specific category.
 */
public abstract class Rygel.Tracker.CategoryContainer : Rygel.SimpleContainer {
    public ItemFactory item_factory;

    public CategoryContainer (string         id,
                              MediaContainer parent,
                              string         title,
                              ItemFactory    item_factory) {
        base (id, parent, title);

        this.item_factory = item_factory;

        this.add_child_container (new CategoryAllContainer (this));
        this.add_child_container (new Tags (this, item_factory));
        this.add_child_container (new Titles (this, this.item_factory));
        this.add_child_container (new New (this, this.item_factory));
    }
}
