/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * Base class for containers listing possible values of a particular LocalSearch
 * metadata key.
 */
public abstract class Rygel.LocalSearch.MetadataContainer : Rygel.SimpleContainer {

    protected ItemFactory item_factory;
    private bool update_in_progress = false;

    private string child_class;

    protected QueryTriplets triplets;

    protected MetadataContainer (string         id,
                                 MediaContainer parent,
                                 string         title,
                                 ItemFactory    item_factory,
                                 string?        child_class = null) {
        base (id, parent, title);

        this.item_factory = item_factory;
        this.child_class = child_class;
    }

    internal async void fetch_metadata_values () {
        if (this.update_in_progress) {
            return;
        }

        this.update_in_progress = true;
        // First thing, clear the existing hierarchy, if any
        this.clear ();

        var query = this.create_query ();

        try {
            yield query.execute (RootContainer.connection);

            /* Iterate through all the values */
            while (query.result.next ()) {
                if (!query.result.is_bound (0)) {
                    continue;
                }

                var value = query.result.get_string (0);

                if (value == "") {
                    continue;
                }

                var title = this.create_title_for_value (value);
                if (title == null) {
                    continue;
                }

                var id = this.create_id_for_title (title);
                if (id == null || !this.is_child_id_unique (id)) {
                    continue;
                }

                var container = this.create_container (id, title, value);

                if (this.child_class != null) {
                    container.upnp_class = child_class;
                }

                this.add_child_container (container);
            }

            query.result.close ();
        } catch (Error error) {
            critical (_("Error getting all values for “%s”: %s"),
                      this.id,
                      error.message);
            this.update_in_progress = false;

            return;
        }

        this.updated ();
        this.update_in_progress = false;
    }

    protected abstract SelectionQuery create_query ();
    protected abstract SearchContainer create_container (string id,
                                                         string title,
                                                         string value);

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws GLib.Error {
        if (this.is_our_child (id)) {
            return yield base.find_object (id, cancellable);
        } else {
            return null;
        }
    }

    protected virtual string? create_id_for_title (string title) {
        return this.id + ":" + Uri.escape_string (title, "", true);
    }

    protected virtual string? create_title_for_value (string value) {
        return value;
    }

    protected virtual string create_filter (string variable, string value) {
        return variable + " = \"" + Query.escape_string (value) + "\"";
    }

    private bool is_our_child (string id) {
        return id.has_prefix (this.id + ":");
    }
}
