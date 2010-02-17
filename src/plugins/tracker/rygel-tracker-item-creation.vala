/*
 * Copyright (C) 2008-2010 Nokia Corporation.
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

using GUPnP;

/**
 * StateMachine interface.
 */
public class Rygel.TrackerItemCreation : GLib.Object, Rygel.StateMachine {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";
    private const string MINER_SERVICE = "org.freedesktop.Tracker1.Miner.Files";
    private const string MINER_PATH = "/org/freedesktop/Tracker1/Miner/Files";

    public Cancellable cancellable { get; set; }
    public Error error { get; set; }

    private MediaItem item;
    private TrackerCategoryContainer category_container;
    private TrackerResourcesIface resources;
    private TrackerMinerIface miner;

    public TrackerItemCreation (MediaItem                item,
                                TrackerCategoryContainer category_container,
                                Cancellable?             cancellable)
                                throws Error {
        this.item = item;
        this.category_container = category_container;
        this.cancellable = cancellable;
        this.create_proxies ();
    }

    public async void run () {
        try {
            var dir = yield this.category_container.get_writable (cancellable);
            if (dir == null) {
                throw new ContentDirectoryError.RESTRICTED_PARENT (
                                        "Object creation in %s no allowed",
                                        this.category_container.id);
            }

            var file = dir.get_child_for_display_name (this.item.title);
            this.item.uris.add (file.get_uri ());

            // First create the item in Tracker store
            var category = this.category_container.item_factory.category;
            var query = new TrackerInsertionQuery (this.item, category);
            yield query.execute (this.resources);

            // Then tell Tracker's Miner to ignore the next update
            var uris = new string[] { this.item.uris[0] };
            yield this.miner.ignore_next_update (uris);

            // Now create the actual file
            yield file.create_async (FileCreateFlags.NONE,
                                     Priority.DEFAULT,
                                     cancellable);

            var expression = new RelationalExpression ();
            expression.op = SearchCriteriaOp.EQ;
            expression.operand1 = "res";
            expression.operand2 = this.item.uris[0];
            uint total_matches;
            var search_results = yield this.category_container.search (
                                        expression,
                                        0,
                                        1,
                                        out total_matches,
                                        this.cancellable);

            var new_item = search_results[0] as MediaItem;
            this.item.id = new_item.id;
            this.item.parent = new_item.parent;
        } catch (GLib.Error error) {
            this.error = error;
        }
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.resources = connection.get_object (TRACKER_SERVICE,
                                                RESOURCES_PATH)
                                                as TrackerResourcesIface;
        this.miner = connection.get_object (MINER_SERVICE,
                                            MINER_PATH)
                                            as TrackerMinerIface;
    }
}

