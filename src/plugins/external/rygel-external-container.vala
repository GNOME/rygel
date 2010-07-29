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
public class Rygel.External.Container : Rygel.MediaContainer {
    public MediaContainerProxy actual_container;

    public string host_ip;
    public string service_name;

    private ItemFactory item_factory;
    private ArrayList<Container> containers;
    private Connection connection;

    private bool searchable;

    public Container (string     id,
                      string     title,
                      uint       child_count,
                      bool       searchable,
                      string     service_name,
                      string     path,
                      string     host_ip,
                      Container? parent = null) {
        base (id, parent, title, (int) child_count);

        this.service_name = service_name;
        this.host_ip = host_ip;
        this.item_factory = new ItemFactory ();
        this.containers = new ArrayList<Container> ();

        try {
            this.connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (GLib.Error err) {
            critical ("Failed to connect to session bus: %s", err.message);
        }

        // Create proxy to MediaContainer iface
        this.actual_container = this.connection.get_object (this.service_name,
                                                            path)
                                as MediaContainerProxy;

        this.update_container.begin (true);
    }

    public override async MediaObjects? get_children (uint         offset,
                                                      uint         max_count,
                                                      Cancellable? cancellable)
                                                      throws GLib.Error {
        string[] filter = {};

        foreach (var object_prop in MediaObjectProxy.PROPERTIES) {
            filter += object_prop;
        }

        foreach (var item_prop in MediaItemProxy.PROPERTIES) {
            filter += item_prop;
        }

        var children_props = yield this.actual_container.list_children (
                                        offset,
                                        max_count,
                                        filter);

        return yield this.create_media_objects (children_props, this);
    }

    public override async MediaObjects? search (SearchExpression expression,
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
        foreach (var object_prop in MediaObjectProxy.PROPERTIES) {
            filter += object_prop;
        }

        foreach (var container_prop in MediaContainerProxy.PROPERTIES) {
            filter += container_prop;
        }

        foreach (var item_prop in MediaItemProxy.PROPERTIES) {
            filter += item_prop;
        }

        var ext_expression = this.translate_expression (expression);
        var result = yield this.actual_container.search_objects (
                                        ext_expression.to_string (),
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
                            as MediaObjectProxy;

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
            var parent_container = new DummyContainer
                                        ((string) actual_object.parent,
                                         "LaLaLa",
                                         0,
                                         null);

            var props_iface = this.connection.get_object (this.service_name, id)
                              as Properties;

            var props = yield props_iface.get_all (MediaItemProxy.IFACE);

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

    private async MediaObjects create_media_objects (
                                        HashTable<string,Value?>[] all_props,
                                        MediaContainer?            parent
                                        = null) throws GLib.Error {
        var media_objects = new MediaObjects ();

        foreach (var props in all_props) {
            var id = props.lookup ("Path").get_string ();
            var type = props.lookup ("Type").get_string ();

            MediaContainer parent_container;
            if (parent != null) {
                parent_container = parent;
            } else {
                var parent_id = props.lookup ("Parent").get_string ();

                parent_container = new DummyContainer (parent_id,
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

                    media_object = new DummyContainer (id,
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

    private async void refresh_child_containers () throws GLib.Error {
        string[] filter = {};

        foreach (var object_prop in MediaObjectProxy.PROPERTIES) {
            filter += object_prop;
        }

        foreach (var container_prop in MediaContainerProxy.PROPERTIES) {
            filter += container_prop;
        }

        var children_props = yield this.actual_container.list_containers (
                                        0,
                                        0,
                                        filter);
        this.containers.clear ();

        foreach (var props in children_props) {
            var path = props.lookup ("Path").get_string ();
            var title = props.lookup ("DisplayName").get_string ();
            var child_count = props.lookup ("ChildCount").get_uint ();
            var searchable = props.lookup ("Searchable").get_boolean ();

            var container = new Container (path,
                                           title,
                                           child_count,
                                           searchable,
                                           this.service_name,
                                           path,
                                           this.host_ip,
                                           this);
            this.containers.add (container);
        }
    }

    private async void update_container (bool connect_signal = false) {
        try {
            // Update our information about the container
            yield this.refresh_child_containers ();
        } catch (GLib.Error err) {
            warning ("Failed to update information about container '%s': %s",
                     this.actual_container.get_path (),
                     err.message);
        }

        // and signal the clients
        this.updated ();

        if (connect_signal) {
            this.actual_container.updated.connect (this.on_updated);
        }
    }

    private void on_updated (MediaContainerProxy actual_container) {
        this.update_container.begin ();
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

    private SearchExpression translate_expression (
                                        SearchExpression upnp_expression) {
        if (upnp_expression is RelationalExpression) {
            var expression = upnp_expression as RelationalExpression;
            var ext_expression = new RelationalExpression ();
            ext_expression.op = expression.op;
            ext_expression.operand1 = this.translate_property (
                                        expression.operand1);
            ext_expression.operand2 = expression.operand2;

            return ext_expression;
        } else {
            var expression = upnp_expression as LogicalExpression;
            var ext_expression = new LogicalExpression ();

            ext_expression.op = expression.op;
            ext_expression.operand1 = this.translate_expression (
                                        expression.operand1);
            ext_expression.operand2 = this.translate_expression (
                                        expression.operand2);

            return ext_expression;
        }
    }

    public string translate_property (string property) {
        switch (property) {
        case "@id":
            return "Path";
        case "@parentID":
            return "Parent";
        case "dc:title":
            return "DisplayName";
        case "dc:creator":
        case "upnp:artist":
        case "upnp:author":
            return "Artist";
        case "upnp:album":
            return "Album";
        default:
            return property;
        }
    }
}

