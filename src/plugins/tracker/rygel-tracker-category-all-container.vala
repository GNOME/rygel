/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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
using Tracker;

/**
 * A search container that contains all the items in a category.
 */
public class Rygel.Tracker.CategoryAllContainer : SearchContainer,
                                                  WritableContainer,
                                                  SearchableContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";

    public ArrayList<string> create_classes { get; set; }
    public ArrayList<string> search_classes { get; set; }

    private Sparql.Connection resources;

    public CategoryAllContainer (CategoryContainer parent) {
        base ("All" + parent.id, parent, "All", parent.item_factory);

        this.create_classes = new ArrayList<string> ();
        this.create_classes.add (item_factory.upnp_class);
        this.search_classes = new ArrayList<string> ();

        try {
            this.resources = Sparql.Connection.get ();
        } catch (Error io_error) {
            critical (_("Failed to create a Tracker connection: %s"),
                      io_error.message);
        }

        try {
            var uri = Filename.to_uri (item_factory.upload_dir, null);
            this.add_uri (uri);
        } catch (ConvertError error) {
            warning (_("Failed to construct URI for folder '%s': %s"),
                     item_factory.upload_dir,
                     error.message);
        }

        try {
            var connection = Bus.get_sync (BusType.SESSION);
            connection.signal_subscribe (TRACKER_SERVICE,
                                         TRACKER_SERVICE + ".Resources",
                                         "GraphUpdated",
                                         RESOURCES_PATH,
                                         this.item_factory.category_iri,
                                         DBusSignalFlags.NONE,
                                         this.on_graph_updated);
        } catch (Error error) {
            critical (_("Could not subscribe to Tracker signals: %s"),
                      error.message);
        }

        var cleanup_query = new CleanupQuery (this.item_factory.category);
        cleanup_query.execute.begin (this.resources);
    }

    public async void add_item (MediaFileItem item, Cancellable? cancellable)
                                throws Error {
        var urn = yield this.create_entry_in_store (item);

        item.id = this.create_child_id_for_urn (urn);
        item.parent = this;
    }

    public async void add_container (MediaContainer container,
                                     Cancellable? cancellable) throws Error {
        throw new WritableContainerError.NOT_IMPLEMENTED (_("Not supported"));
    }

    public async void remove_item (string id, Cancellable? cancellable)
                                   throws Error {
        string parent_id;

        var urn = this.get_item_info (id, out parent_id);

        yield this.remove_entry_from_store (urn);
    }

    public async void remove_container (string id, Cancellable? cancellable)
                                        throws Error {
        throw new WritableContainerError.NOT_IMPLEMENTED ("Not supported");
    }

    public async MediaObjects? search (SearchExpression? expression,
                                       uint              offset,
                                       uint              max_count,
                                       out uint          total_matches,
                                       string            sort_criteria,
                                       Cancellable?      cancellable)
                                       throws Error {
        return yield this.simple_search (expression,
                                         offset,
                                         max_count,
                                         out total_matches,
                                         sort_criteria,
                                         cancellable);
    }

    private void on_graph_updated (DBusConnection connection,
                                   string         sender,
                                   string         object_path,
                                   string         interface_name,
                                   string         signal_path,
                                   Variant        parameters) {
        this.get_children_count.begin ();
    }

    private async string create_entry_in_store (MediaFileItem item)
                                                throws Error {
        var category = this.item_factory.category;
        var query = new InsertionQuery (item, category);

        yield query.execute (this.resources);

        return query.id;
    }

    private async void remove_entry_from_store (string id) throws Error {
        var query = new DeletionQuery (id);

        yield query.execute (this.resources);
    }
}

