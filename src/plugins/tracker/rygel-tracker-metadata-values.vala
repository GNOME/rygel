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
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    private const string METADATA_PATH = "/org/freedesktop/Tracker/Metadata";
    private const string METADATA_IFACE = "org.freedesktop.Tracker.Metadata";

    private const string SERVICE = "Files";
    private const string QUERY_CONDITION =
        "<rdfq:Condition>\n" +
                "<rdfq:equals>\n" +
                    "<rdfq:Property name=\"%s\" />\n" +
                    "<rdf:String>%s</rdf:String>\n" +
                "</rdfq:equals>\n" +
        "</rdfq:Condition>";

    public dynamic DBus.Object metadata;

    public string key;

    public TrackerMetadataValues (string         key,
                                  string         id,
                                  MediaContainer parent,
                                  string         title) {
        base (id, parent, title);

        this.key = key;

        try {
            this.create_proxies ();

            var keys = new string[] { this.key };

            /* FIXME: We need to hook to some tracker signals to keep
             *        this field up2date at all times
             */
            this.metadata.GetUniqueValues (SERVICE,
                                           keys,
                                           "",
                                           true,
                                           0,
                                           -1,
                                           on_get_unique_values_cb);
        } catch (GLib.Error error) {
            critical ("Failed to create to Session bus: %s\n",
                      error.message);
        }
    }

    private void on_get_unique_values_cb (string[][] search_result,
                                          GLib.Error error) {
        if (error != null) {
            critical ("error getting all values for '%s': %s",
                      this.key,
                      error.message);

            return;
        }

        /* Iterate through all the values */
        for (uint i = 0; i < search_result.length; i++) {
            string value = search_result[i][0];

            var query_condition = QUERY_CONDITION.printf (
                                        this.key,
                                        Markup.escape_text (value));
            var container = new TrackerSearchContainer (value,
                                                        this,
                                                        value,
                                                        SERVICE,
                                                        query_condition);

            this.children.add (container);
        }

        this.child_count = this.children.size;
        this.updated ();
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.metadata = connection.get_object (TRACKER_SERVICE,
                                               METADATA_PATH,
                                               METADATA_IFACE);
    }
}

