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
using DBus;
using Gee;

/**
 * Container listing possible values of a particuler Tracker metadata key.
 */
public class Rygel.TrackerMetadataValues : Rygel.SimpleContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";
    private const string ITEM_VARIABLE = "?item";

    public delegate string IDFunc (string value);
    public delegate string FilterFunc (string variable, string value);

    private TrackerItemFactory item_factory;

    // In tracker 0.7, we might don't get values of keys in place so you need a
    // chain of keys to reach to final destination. For instances:
    // nmm:Performer -> nmm:artistName
    public string[] key_chain;
    public IDFunc id_func;
    public IDFunc title_func;
    public FilterFunc filter_func;

    private TrackerResourcesIface resources;
    private TrackerResourcesClassIface resources_class;

    public TrackerMetadataValues (string             id,
                                  MediaContainer     parent,
                                  string             title,
                                  TrackerItemFactory item_factory,
                                  string[]           key_chain,
                                  IDFunc?            id_func =
                                        default_id_func,
                                  IDFunc?            title_func =
                                        default_id_func,
                                  FilterFunc?        filter_func =
                                        default_filter_func) {
        base (id, parent, title);

        this.item_factory = item_factory;
        this.key_chain = key_chain;
        this.id_func = id_func;
        this.title_func = title_func;
        this.filter_func = filter_func;

        try {
            this.create_proxies ();
        } catch (DBus.Error error) {
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
        var triplets = new TrackerQueryTriplets ();

        // All variables used in the query
        var num_keys = this.key_chain.length - 1;
        var variables = new string[num_keys];
        for (i = 0; i < num_keys; i++) {
            variables[i] = "?" + key_chain[i].replace (":", "_");

            string subject;
            if (i == 0) {
                subject = ITEM_VARIABLE;
            } else {
                subject = variables[i - 1];
            }

            triplets.add (new TrackerQueryTriplet (subject,
                                                   this.key_chain[i],
                                                   variables[i]));
        }

        triplets.insert (0, new TrackerQueryTriplet (
                                        ITEM_VARIABLE,
                                        "a",
                                        this.item_factory.category));

        // Variables to select from query
        var selected = new ArrayList<string> ();
        // Last variable is the only thing we are interested in the result
        var last_variable = variables[num_keys - 1];
        selected.add ("DISTINCT " + last_variable);

        var query = new TrackerSelectionQuery (selected,
                                               triplets,
                                               null,
                                               last_variable);

        try {
            yield query.execute (this.resources);
        } catch (DBus.Error error) {
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

            var id = this.id_func (value);
            if (!this.is_child_id_unique (id)) {
                continue;
            }

            var title = this.title_func (value);

            // The child container can use the same triplets we used in our
            // query.
            var child_triplets = new TrackerQueryTriplets.clone (triplets);

            // However we constrain the object of our last triplet.
            var filters = new ArrayList<string> ();
            var filter = this.filter_func (child_triplets.last ().obj, value);
            filters.add (filter);

            var container = new TrackerSearchContainer (id,
                                                        this,
                                                        title,
                                                        this.item_factory,
                                                        child_triplets,
                                                        filters);

            this.add_child (container);
        }

        this.updated ();
    }

    public static string default_id_func (string value) {
        return value;
    }

    public static string default_filter_func (string variable, string value) {
        return variable + " = \"" + value + "\"";
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.resources = connection.get_object (TRACKER_SERVICE,
                                                RESOURCES_PATH)
                                                as TrackerResourcesIface;
        this.resources_class = connection.get_object (
                                        TRACKER_SERVICE,
                                        this.item_factory.resources_class_path)
                                        as TrackerResourcesClassIface;
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

