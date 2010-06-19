/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009,2010 Nokia Corporation.
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
using DBus;
using Gee;
using FreeDesktop;

/**
 * Represents an external container.
 */
public class Rygel.ExternalContainer : Rygel.MediaContainer {
    public ExternalMediaContainer actual_container;

    public string host_ip;
    public string service_name;

    private ExternalItemFactory item_factory;
    private ArrayList<ExternalContainer> containers;
    private Connection connection;

    private bool searchable;

    public ExternalContainer (string                 id,
                              string                 service_name,
                              string                 host_ip,
                              ExternalMediaContainer actual_container,
                              ExternalContainer?     parent = null) {
        base (id,
              parent,
              actual_container.display_name,
              (int) actual_container.child_count);

        this.service_name = service_name;
        this.host_ip = host_ip;
        this.actual_container = actual_container;
        this.searchable = actual_container.searchable;
        this.item_factory = new ExternalItemFactory ();

        this.containers = new ArrayList<ExternalContainer> ();

        try {
            this.connection = Bus.get (DBus.BusType.SESSION);

            this.update_container ();

            this.actual_container.updated.connect (this.on_updated);
        } catch (GLib.Error err) {
            critical ("Failed to fetch information about container '%s': %s",
                      actual_container.get_path (),
                      err.message);
        }
    }

    public override async Gee.List<MediaObject>? get_children (
                                        uint         offset,
                                        uint         max_count,
                                        Cancellable? cancellable)
                                        throws GLib.Error {
        string[] filter = {};

        foreach (var object_prop in ExternalMediaObject.PROPERTIES) {
            filter += object_prop;
        }

        foreach (var item_prop in ExternalMediaItem.PROPERTIES) {
            filter += item_prop;
        }

        var children_props = yield this.actual_container.list_children (
                                        offset,
                                        max_count,
                                        filter);

        return yield this.create_media_objects (children_props, this);
    }

    public override async Gee.List<MediaObject>? search (
                                        SearchExpression expression,
                                        uint             offset,
                                        uint             max_count,
                                        out uint         total_matches,
                                        Cancellable?     cancellable)
                                        throws GLib.Error {
        if (!this.searchable) {
            // Backend doesn't implement search :(
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      cancellable);
        }

        string[] filter = {};
        foreach (var object_prop in ExternalMediaObject.PROPERTIES) {
            filter += object_prop;
        }

        foreach (var container_prop in ExternalMediaContainer.PROPERTIES) {
            filter += container_prop;
        }

        foreach (var item_prop in ExternalMediaItem.PROPERTIES) {
            filter += item_prop;
        }

        var result = yield this.actual_container.search_objects (
                                        expression.to_string (),
                                        offset,
                                        max_count,
                                        filter);
        total_matches = result.length;

        return yield this.create_media_objects (result);
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws GLib.Error {
        MediaObject media_object = null;

        // Create proxy to MediaObject iface
        var actual_object = this.connection.get_object (this.service_name, id)
                            as ExternalMediaObject;

        if (actual_object.object_type == "container") {
            media_object = this.find_container_by_id (id);

            if (media_object == null) {
                // Not a child container, lets search in child containers then
                foreach (var container in this.containers) {
                    media_object = yield container.find_object (id,
                                                                cancellable);

                    if (media_object != null) {
                        break;
                    }
                }
            }
        } else {
            var parent_container = new ExternalDummyContainer
                                        ((string) actual_object.parent,
                                         "LaLaLa",
                                         0,
                                         null);

            var props_iface = this.connection.get_object (this.service_name, id)
                              as Properties;

            var props = yield props_iface.get_all (ExternalMediaItem.IFACE);

            // Its an item then
            media_object = yield this.item_factory.create (
                                        id,
                                        actual_object.object_type,
                                        actual_object.display_name,
                                        props,
                                        this.service_name,
                                        this.host_ip,
                                        parent_container);
        }

        return media_object;
    }

    private async Gee.List<MediaObject> create_media_objects (
                                        HashTable<string,Value?>[] all_props,
                                        MediaContainer?            parent
                                        = null) throws GLib.Error {
        var media_objects = new ArrayList <MediaObject> ();

        foreach (var props in all_props) {
            var id = props.lookup ("Path").get_string ();
            var type = props.lookup ("Type").get_string ();

            MediaContainer parent_container;
            if (parent != null) {
                parent_container = parent;
            } else {
                var parent_id = props.lookup ("Parent").get_string ();

                parent_container = new ExternalDummyContainer (parent_id,
                                                               "LaLaLa",
                                                               0,
                                                               null);
            }

            MediaObject media_object = null;
            if (type == "container") {
                media_object = this.find_container_by_id (id);
            }

            if (media_object == null) {
                var title = props.lookup ("DisplayName").get_string ();

                if (type == "container") {
                    var child_count = props.lookup ("ChildCount").get_uint ();

                    media_object = new ExternalDummyContainer (
                                        id,
                                        title,
                                        child_count,
                                        parent_container);
                } else {
                    // Its an item then
                    media_object = yield this.item_factory.create (
                                        id,
                                        type,
                                        title,
                                        props,
                                        this.service_name,
                                        this.host_ip,
                                        parent_container);
                }
            }

            media_objects.add (media_object);
        }

        return media_objects;
    }

    private void update_container () throws GLib.Error {
        this.containers.clear ();

        var container_paths = this.actual_container.containers;
        foreach (var container_path in container_paths) {
            // Create proxy to MediaContainer iface
            var actual_container = this.connection.get_object (
                                        this.service_name,
                                        container_path)
                                        as ExternalMediaContainer;

            var container = new ExternalContainer (container_path,
                                                   this.service_name,
                                                   this.host_ip,
                                                   actual_container,
                                                   this);
            this.containers.add (container);
        }
    }

    private void on_updated (ExternalMediaContainer actual_container) {
        try {
            // Update our information about the container
            this.update_container ();
        } catch (GLib.Error err) {
            warning ("Failed to update information about container '%s': %s",
                     this.actual_container.get_path (),
                     err.message);
        }

        // and signal the clients
        this.updated ();
    }

    private MediaContainer find_container_by_id (string id) {
        MediaContainer target = null;

        foreach (var container in this.containers) {
            if (container.id == id) {
                target = container;

                break;
            }
        }

        return target;
    }
}

