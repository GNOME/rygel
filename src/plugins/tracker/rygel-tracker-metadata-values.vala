/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using GUPnP;
using Gee;

/**
 * Container listing possible values of a particuler Tracker metadata key.
 */
public abstract class Rygel.Tracker.MetadataValues : Rygel.SimpleContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";

    private ItemFactory item_factory;

    // In tracker 0.7, we might don't get values of keys in place so you need a
    // chain of keys to reach to final destination. For instances:
    // nmm:Performer -> nmm:artistName
    public string[] key_chain;

    private string child_class;

    private ResourcesIface resources;
    private ResourcesClassIface resources_class;

    public MetadataValues (string         id,
                           MediaContainer parent,
                           string         title,
                           ItemFactory    item_factory,
                           string[]       key_chain,
                           string?        child_class = null) {
        base (id, parent, title);

        this.item_factory = item_factory;
        this.key_chain = key_chain;
        this.child_class = child_class;

        try {
            this.create_proxies ();
        } catch (IOError error) {
            critical (_("Failed to connect to session bus: %s"), error.message);

            return;
        }

        this.fetch_metadata_values.begin ();

        this.hook_to_changes ();
    }

    private async void fetch_metadata_values () {
        // First thing, clear the existing hierarchy, if any
        this.clear ();

        int i;
        var triplets = new QueryTriplets ();

        triplets.add (new QueryTriplet (SelectionQuery.ITEM_VARIABLE,
                                        "a",
                                        this.item_factory.category));

        // All variables used in the query
        var num_keys = this.key_chain.length - 1;
        var variables = new string[num_keys];
        for (i = 0; i < num_keys; i++) {
            variables[i] = "?" + key_chain[i].replace (":", "_");

            string subject;
            if (i == 0) {
                subject = SelectionQuery.ITEM_VARIABLE;
            } else {
                subject = variables[i - 1];
            }

            triplets.add (new QueryTriplet (subject,
                                            this.key_chain[i],
                                            variables[i]));
        }

        // Variables to select from query
        var selected = new ArrayList<string> ();
        // Last variable is the only thing we are interested in the result
        var last_variable = variables[num_keys - 1];
        selected.add ("DISTINCT " + last_variable);

        var query = new SelectionQuery (selected,
                                        triplets,
                                        null,
                                        last_variable);

        try {
            yield query.execute (this.resources);
        } catch (IOError error) {
            critical (_("Error getting all values for '%s': %s"),
                      string.joinv (" -> ", this.key_chain),
                      error.message);

            return;
        }

        /* Iterate through all the values */
        for (i = 0; i < query.result.length[0]; i++) {
            string value = query.result[i, 0];

            if (value == "") {
                continue;
            }

            var title = this.create_title_for_value (value);
            var id = this.create_id_for_title (title);
            if (!this.is_child_id_unique (id)) {
                continue;
            }

            // The child container can use the same triplets we used in our
            // query.
            var child_triplets = new QueryTriplets.clone (triplets);

            // However we constrain the object of our last triplet.
            var filters = new ArrayList<string> ();
            var filter = this.create_filter (child_triplets.last ().obj, value);
            filters.add (filter);

            var container = new SearchContainer (id,
                                                 this,
                                                 title,
                                                 this.item_factory,
                                                 child_triplets,
                                                 filters);
            if (this.child_class != null) {
                container.upnp_class = child_class;
            }

            this.add_child (container);
        }

        this.updated ();
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws GLib.Error {
        if (this.is_our_child (id)) {
            return yield base.find_object (id, cancellable);
        } else {
            return null;
        }
    }

    protected virtual string create_id_for_title (string title) {
        return this.id + ":" + Uri.escape_string (title, "", true);
    }

    protected virtual string create_title_for_value (string value) {
        return value;
    }

    protected virtual string create_filter (string variable, string value) {
        return variable + " = \"" + value + "\"";
    }

    private bool is_our_child (string id) {
        return id.has_prefix (this.id + ":");
    }

    private void create_proxies () throws IOError {
        this.resources = Bus.get_proxy_sync (BusType.SESSION,
                                             TRACKER_SERVICE,
                                             RESOURCES_PATH);
        this.resources_class = Bus.get_proxy_sync (
                                        BusType.SESSION,
                                        TRACKER_SERVICE,
                                        this.item_factory.resources_class_path);
    }

    private void hook_to_changes () {
        // For any changes in subjects, just recreate hierarchy
        this.resources_class.subjects_added.connect ((subjects) => {
            this.fetch_metadata_values.begin ();
        });
        this.resources_class.subjects_removed.connect ((subjects) => {
            this.fetch_metadata_values.begin ();
        });
        this.resources_class.subjects_changed.connect ((before, after) => {
            this.fetch_metadata_values.begin ();
        });
    }

    private bool is_child_id_unique (string child_id) {
        var unique = true;

        foreach (var child in this.children) {
            if (child.id == child_id) {
                unique = false;

                break;
            }
        }

        return unique;
    }
}

