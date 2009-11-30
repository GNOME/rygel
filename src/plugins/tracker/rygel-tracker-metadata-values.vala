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

    private string category;

    // In tracker 0.7, we might don't get values of keys in place so you need a
    // chain of keys to reach to final destination. For instances:
    // nmm:Performer -> nmm:artistName
    public string[] key_chain;

    private TrackerResourcesIface resources;

    public TrackerMetadataValues (string         id,
                                  MediaContainer parent,
                                  string         title,
                                  string         category,
                                  string[]       key_chain) {
        base (id, parent, title);

        this.category = category;
        this.key_chain = key_chain;

        try {
            this.create_proxies ();
        } catch (DBus.Error error) {
            critical ("Failed to create to Session bus: %s\n",
                      error.message);

            return;
        }

        this.fetch_metadata_values.begin ();
    }

    private async void fetch_metadata_values () {
        int i;
        var mandatory = new TrackerQueryTriplets ();

        // All variables used in the query
        var num_keys = this.key_chain.length - 1;
        var variables = new string[num_keys];
        for (i = 0; i < num_keys; i++) {
            variables[i] = "?" + key_chain[i].replace (":", "_");

            string subject;
            if (i == 0) {
                subject = null;
            } else {
                subject = variables[i - 1];
            }

            mandatory.add (new TrackerQueryTriplet (subject,
                                                    this.key_chain[i],
                                                    variables[i],
                                                    false));
        }

        mandatory.insert (0, new TrackerQueryTriplet (ITEM_VARIABLE,
                                                      "a",
                                                      this.category,
                                                      false));

        // Variables to select from query
        var selected = new ArrayList<string> ();
        // Last variable is the only thing we are interested in the result
        var last_variable = variables[num_keys - 1];
        selected.add ("DISTINCT " + last_variable);

        var query = new TrackerQuery (selected,
                                      mandatory,
                                      null,
                                      null,
                                      last_variable);

        string[,] values;
        try {
            /* FIXME: We need to hook to some tracker signals to keep
             *        this field up2date at all times
             */
            debug ("Executing SPARQL query: %s", query.to_string ());
            values = yield this.resources.sparql_query (query.to_string ());
        } catch (DBus.Error error) {
            critical ("error getting all values for '%s': %s",
                      string.joinv (" -> ", this.key_chain),
                      error.message);

            return;
        }

        /* Iterate through all the values */
        for (i = 0; i < values.length[0]; i++) {
            string value = values[i, 0];

            if (value == "") {
                continue;
            }

            // The child container can use the same mandatory triplets we used
            // in our query except that last value is now fixed
            mandatory.last ().obj = "\"" + value + "\"";

            var container = new TrackerSearchContainer (value,
                                                        this,
                                                        value,
                                                        this.category,
                                                        mandatory,
                                                        null);

            this.add_child (container);
        }

        this.updated ();
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.resources = connection.get_object (TRACKER_SERVICE,
                                                RESOURCES_PATH)
                                                as TrackerResourcesIface;
    }
}

