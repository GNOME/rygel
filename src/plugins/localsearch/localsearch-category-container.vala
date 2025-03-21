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

using Gee;

/**
 * Container listing content hierarchy for a specific category.
 */
public abstract class Rygel.LocalSearch.CategoryContainer : Rygel.SimpleContainer {
    public ItemFactory item_factory;

    private CategoryAllContainer all_container;

    protected CategoryContainer (string         id,
                                 MediaContainer parent,
                                 string         title,
                                 ItemFactory    item_factory) {
        base (id, parent, title);

        this.item_factory = item_factory;

        this.all_container = new CategoryAllContainer (this);

        this.add_child_container (this.all_container);
        this.add_child_container (new Tags (this, item_factory));
        this.add_child_container (new Titles (this, this.item_factory));
        this.add_child_container (new New (this, this.item_factory));
        ulong signal_id = 0;

        signal_id = this.all_container.container_updated.connect( () => {
            // ingore first update
            this.all_container.container_updated.connect
                                        (this.on_all_container_updated);
            this.all_container.disconnect (signal_id);
        });
    }

    public void add_create_class (string create_class) {
        this.all_container.create_classes.add (create_class);
    }

    private void trigger_child_update (MediaObjects children) {
        foreach (var container in children) {
            if (container == this.all_container ||
                container == null) {
                continue;
            }

            if (container is MetadataValues) {
                ((MetadataValues) container).fetch_metadata_values.begin ();
            } else if (container is SearchContainer) {
                ((SearchContainer) container).get_children_count.begin ();
            }
        }
    }

    private void on_all_container_updated (MediaContainer other) {
        if (other != this.all_container) {
            // otherwise we'd do a recursive update
            return;
        }

        this.trigger_child_update (this.get_all_children ());
    }
}
