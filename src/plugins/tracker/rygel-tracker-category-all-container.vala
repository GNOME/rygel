/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                                <zeeshan.ali@nokia.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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

    private QueryHelper query_helper;
    private ResourcesIface resources;

    public CategoryAllContainer (CategoryContainer parent) {
        base ("All" + parent.id, parent, "All", parent.item_factory);

        this.query_helper = new QueryHelper (this);

        this.create_classes = new ArrayList<string> ();
        this.create_classes.add (item_factory.upnp_class);
        this.search_classes = new ArrayList<string> ();

        try {
            this.resources = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         TRACKER_SERVICE,
                                         RESOURCES_PATH,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
        } catch (IOError io_error) {
            critical (_("Failed to create D-Bus proxies: %s"),
                      io_error.message);
        }

        try {
            var uri = Filename.to_uri (item_factory.upload_dir, null);
            this.uris.add (uri);
        } catch (ConvertError error) {
            warning (_("Failed to construct URI for folder '%s': %s"),
                     item_factory.upload_dir,
                     error.message);
        }

        unowned DBusConnection connection = this.resources.get_connection ();
        connection.signal_subscribe (TRACKER_SERVICE,
                                     TRACKER_SERVICE + ".Resources",
                                     "GraphUpdated",
                                     RESOURCES_PATH,
                                     this.item_factory.category_iri,
                                     DBusSignalFlags.NONE,
                                     this.on_graph_updated);
    }

    public async void add_item (MediaItem item, Cancellable? cancellable)
                                throws Error {
        var urn = yield this.create_entry_in_store (item);

        item.id = this.create_child_id_for_urn (urn);
        item.parent = this;
    }

    public async void remove_item (string id, Cancellable? cancellable)
                                   throws Error {
        string parent_id;

        var urn = this.get_item_info (id, out parent_id);

        yield this.remove_entry_from_store (urn);
    }

    public async MediaObjects? search (SearchExpression? expression,
                                       uint              offset,
                                       uint              max_count,
                                       out uint          total_matches,
                                       Cancellable?      cancellable)
                                       throws Error {
        var query = this.query_helper.create_query (expression,
                                                    null,
                                                    offset,
                                                    max_count,
                                                    cancellable);

        yield query.execute (this.resources);

        total_matches = yield query.get_count (this.resources);

        return this.query_helper.get_results (query);
    }

    private void on_graph_updated (DBusConnection connection,
                                   string         sender,
                                   string         object_path,
                                   string         interface_name,
                                   string         signal_path,
                                   Variant        parameters) {
        this.get_children_count.begin ();
    }

    private async string create_entry_in_store (MediaItem item) throws Error {
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

