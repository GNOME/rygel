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

public errordomain TrackerItemCreationError {
    TIMEOUT
}

/**
 * StateMachine interface.
 */
public class Rygel.TrackerItemCreation : GLib.Object, Rygel.StateMachine {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string RESOURCES_PATH = "/org/freedesktop/Tracker1/Resources";
    private const uint ITEM_CREATION_TIMEOUT = 5;

    public Cancellable cancellable { get; set; }
    public Error error { get; set; }

    private MediaItem item;
    private TrackerCategoryContainer category_container;
    private TrackerResourcesIface resources;

    private SourceFunc run_continue = null;
    private bool added = false;

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
        this.item.id = "<" + this.item.uris[0] + ">";

        var category = this.category_container.item_factory.category;
        var query = new TrackerInsertionQuery (this.item, category);

        var handler_id = this.category_container.container_updated.connect
                                        (this.on_container_updated);

        try {
            yield query.execute (this.resources);
        } catch (DBus.Error error) {
            this.error = error;

            return;
        }

        if (!added) {
            // The new item still haven't been picked up, lets wait for it
            // a bit
            this.run_continue = this.run.callback;

            Timeout.add_seconds (ITEM_CREATION_TIMEOUT,
                                 this.on_item_creation_timeout);

            yield;
        }

        SignalHandler.disconnect (this.category_container, handler_id);
    }

    private void on_container_updated (MediaContainer updated_container) {
        this.on_container_updated_async.begin (updated_container);
    }

    private bool on_item_creation_timeout () {
        this.run_continue ();
        this.error = new TrackerItemCreationError.TIMEOUT (
                                        "Timeout while waiting for item" +
                                        "creation signal from Tracker");

        return false;
    }

    private async void on_container_updated_async (
                                        MediaContainer updated_container) {
        Gee.List<MediaObject> children;

        try {
            children = yield updated_container.get_children (0,
                                                             -1,
                                                             this.cancellable);
        } catch (Error error) {
            warning ("Error listing children of '%s': %s",
                     updated_container.id,
                     error.message);

            return;
        }

        foreach (var child in children) {
            foreach (var uri in child.uris) {
                if (uri == this.item.uris[0]) {
                    added = true;

                    break;
                }
            }

            if (added) {
                if (this.run_continue != null) {
                    this.run_continue ();
                }

                break;
            }
        }
    }

    private void create_proxies () throws DBus.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.resources = connection.get_object (TRACKER_SERVICE,
                                                RESOURCES_PATH)
                                                as TrackerResourcesIface;
    }
}

