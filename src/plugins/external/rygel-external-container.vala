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
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;
using Gee;
using Rygel.External.FreeDesktop;

/**
 * Represents an external container.
 */
public class Rygel.External.Container : Rygel.MediaContainer,
                                        Rygel.SearchableContainer {
    public MediaContainerProxy actual_container;

    public string service_name;

    private ItemFactory item_factory;
    private ArrayList<Container> containers;
    public ArrayList<string> search_classes { get; set; }

    private bool searchable;

    public Container (string     id,
                      string     title,
                      uint       child_count,
                      bool       searchable,
                      string     service_name,
                      string     path,
                      Container? parent = null) throws IOError {
        var tmp = (int) child_count.clamp (0, int.MAX);
        if (tmp == int.MAX) {
            tmp = -1;
        }
        base (id, parent, title, tmp);

        this.service_name = service_name;
        this.item_factory = new ItemFactory ();
        this.containers = new ArrayList<Container> ();
        this.search_classes = new ArrayList<string> ();

        // default: use sort order of external container, no additional
        // sort criteria
        this.sort_criteria = "";

        // Create proxy to MediaContainer iface
        this.actual_container = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         this.service_name,
                                         path,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

        this.update_container.begin (true);
        if (parent != null) {
            parent.add_weak_pointer (&this.parent_ptr);
        }
    }

    ~Container() {
        if (this.parent != null) {
            this.parent.remove_weak_pointer (&this.parent_ptr);
        }
    }

    public override async MediaObjects? get_children (
                                                     uint         offset,
                                                     uint         max_count,
                                                     string       sort_criteria,
                                                     Cancellable? cancellable)
                                                     throws GLib.Error {
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

        var children_props = yield this.actual_container.list_children
                                        (offset, max_count, filter);

        var result = yield this.create_media_objects (children_props, this);
        result.sort_by_criteria (sort_criteria);

        return result;
    }

    public async MediaObjects? search (SearchExpression? expression,
                                       uint              offset,
                                       uint              max_count,
                                       string            sort_criteria,
                                       Cancellable?      cancellable,
                                       out uint          total_matches)
                                       throws GLib.Error {
        if (expression == null || !this.searchable) {
            // Either its wildcard or backend doesn't implement search :(
            return yield this.simple_search (expression,
                                             offset,
                                             max_count,
                                             sort_criteria,
                                             cancellable,
                                             out total_matches);
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
        var result = yield this.actual_container.search_objects
                                        (ext_expression.to_string (),
                                         offset,
                                         max_count,
                                         filter);
        total_matches = result.length;

        var objects = yield this.create_media_objects (result);

        // FIXME: Delegate sorting to remote peer
        objects.sort_by_criteria (sort_criteria);

        return objects;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws GLib.Error {
        MediaObject media_object = null;

        // Create proxy to MediaObject iface
        MediaObjectProxy actual_object = yield Bus.get_proxy (BusType.SESSION,
                                                             this.service_name,
                                                             id);

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

                // still not found; could be it's a child of a container we
                // couldn't browse at create-time since it had an unknown
                // number of children
                Properties props_iface = yield Bus.get_proxy
                                            (BusType.SESSION,
                                             this.service_name,
                                             id,
                                             DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

                var props = yield props_iface.get_all (MediaContainerProxy.IFACE);
                var child_count = (uint) props.lookup ("ChildCount");
                var searchable = (bool) props.lookup ("Searchable");
                props = yield props_iface.get_all (MediaObjectProxy.IFACE);
                var path = (string) props.lookup ("Path");
                var title = get_mandatory_string_value (props,
                                                        "DisplayName",
                                                        path,
                                                        this.service_name);

                media_object = new Container (path,
                                              title,
                                              child_count,
                                              searchable,
                                              this.service_name,
                                              path,
                                              this);
            }
        } else {
            var parent_container = new DummyContainer
                                        ((string) actual_object.parent,
                                         "LaLaLa",
                                         0,
                                         null);

            Properties props_iface = yield Bus.get_proxy
                                        (BusType.SESSION,
                                         this.service_name,
                                         id,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

            var props = yield props_iface.get_all (MediaItemProxy.IFACE);

            // Its an item then
            media_object = yield this.item_factory.create
                                        (id,
                                         actual_object.object_type,
                                         actual_object.display_name,
                                         props,
                                         this.service_name,
                                         parent_container);
        }

        return media_object;
    }

    private async MediaObjects create_media_objects
                                   (HashTable<string, Variant>[] all_props,
                                    MediaContainer?              parent = null)
                                    throws GLib.Error {
        var media_objects = new MediaObjects ();

        foreach (var props in all_props) {
            var id = (string) props.lookup ("Path");
            var type = (string) props.lookup ("Type");

            MediaContainer parent_container;
            if (parent != null) {
                parent_container = parent;
            } else {
                var parent_id = (string) props.lookup ("Parent");

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
                var title = get_mandatory_string_value (props,
                                                        "DisplayName",
                                                        id,
                                                        this.service_name);

                if (type == "container") {
                    var child_count = (uint) props.lookup ("ChildCount");

                    media_object = new DummyContainer (id,
                                                       title,
                                                       child_count,
                                                       parent_container);
                } else {
                    // Its an item then
                    media_object = yield this.item_factory.create
                                        (id,
                                         type,
                                         title,
                                         props,
                                         this.service_name,
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

        var children_props = yield this.actual_container.list_containers
                                        (0, 0, filter);
        this.containers.clear ();

        foreach (var props in children_props) {
            var path = (string) props.lookup ("Path");
            var title = (string) props.lookup ("DisplayName");
            var child_count = (uint) props.lookup ("ChildCount");
            var searchable = (bool) props.lookup ("Searchable");

            var container = new Container (path,
                                           title,
                                           child_count,
                                           searchable,
                                           this.service_name,
                                           path,
                                           this);
            this.containers.add (container);
        }
    }

    private async void update_container (bool connect_signal = false) {
        try {
            Properties props_iface = yield Bus.get_proxy
                                        (BusType.SESSION,
                                         this.service_name,
                                         this.actual_container.get_object_path (),
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
            var props = yield props_iface.get_all (MediaContainerProxy.IFACE);
            var child_count = (uint) props.lookup ("ChildCount");
            // Check if peer knows its child count
            if (child_count < int.MAX) {
                this.child_count = (int) child_count;
            }
            props = yield props_iface.get_all (MediaObjectProxy.IFACE);

            this.title = get_mandatory_string_value (props,
                                                     "DisplayName",
                                                     this.id,
                                                     this.service_name);
        } catch (GLib.Error property_error) {
            warning ("Failed to update information about container '%s': %s",
                     this.actual_container.get_object_path (),
                     property_error.message);
        }

        try {
            if (this.child_count < int.MAX) {
                // Update our information about the container
                yield this.refresh_child_containers ();
            }
        } catch (GLib.Error err) {
            warning ("Failed to update information about container '%s': %s",
                     this.actual_container.get_object_path (),
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

    private SearchExpression translate_expression
                                        (SearchExpression upnp_expression) {
        if (upnp_expression is RelationalExpression) {
            var expression = upnp_expression as RelationalExpression;
            var ext_expression = new RelationalExpression ();
            ext_expression.op = expression.op;
            ext_expression.operand1 = this.translate_property
                                        (expression.operand1);
            ext_expression.operand2 = expression.operand2;

            return ext_expression;
        } else {
            var expression = upnp_expression as LogicalExpression;
            var ext_expression = new LogicalExpression ();

            ext_expression.op = expression.op;
            ext_expression.operand1 = this.translate_expression
                                        (expression.operand1);
            ext_expression.operand2 = this.translate_expression
                                        (expression.operand2);

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

