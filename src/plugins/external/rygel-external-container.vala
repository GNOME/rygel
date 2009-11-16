/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
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

/**
 * Represents an external container.
 */
public class Rygel.ExternalContainer : Rygel.MediaContainer {
    public ExternalMediaContainer actual_container;

    public string host_ip;

    public string service_name;
    private string object_path;

    private ArrayList<ExternalContainer> containers;

    public ExternalContainer (string             id,
                              string             service_name,
                              string             object_path,
                              string             host_ip,
                              ExternalContainer? parent) {
        base (id, parent, "Uknown", 0);

        this.service_name = service_name;
        this.object_path = object_path;
        this.host_ip = host_ip;

        this.containers = new ArrayList<ExternalContainer> ();

        try {
            DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

            // Create proxy to MediaContainer iface
            this.actual_container = connection.get_object (
                                        service_name,
                                        object_path)
                                        as ExternalMediaContainer;
            this.title = this.actual_container.display_name;

            this.update_container ();

            this.actual_container.updated += this.on_updated;
        } catch (GLib.Error err) {
            critical ("Failed to fetch information about container '%s': %s\n",
                      this.id,
                      err.message);
        }
    }

    public override async Gee.List<MediaObject>? get_children (
                                        uint         offset,
                                        uint         max_count,
                                        Cancellable? cancellable)
                                        throws GLib.Error {
        var media_objects = new ArrayList <MediaObject> ();

        // First add the child containers
        media_objects.add_all (this.containers);

        // Then get and add the child items
        var obj_paths = this.actual_container.items;
        var factory = new ExternalItemFactory ();
        foreach (var obj_path in obj_paths) {
            try {
                var item = yield factory.create_for_path (obj_path, this);

                media_objects.add (item);
            } catch (GLib.Error err) {
                warning ("Error initializable item at '%s': %s. Ignoring..",
                        obj_path,
                        err.message);
            }
        }

        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);

        return media_objects.slice ((int) offset, (int) stop);
    }

    public override async Gee.List<MediaObject>? search (
                                        SearchExpression expression,
                                        uint             offset,
                                        uint             max_count,
                                        out uint         total_matches,
                                        Cancellable?     cancellable)
                                        throws GLib.Error {
        var results = new ArrayList<MediaObject> ();

        /* We only deal with relational expression */
        if (expression == null || !(expression is RelationalExpression)) {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      cancellable);
        }

        var rel_expression = expression as RelationalExpression;
        var id = rel_expression.operand2;

        /* We only deal with search for a particular item */
        if (rel_expression.operand1 != "@id" ||
            rel_expression.op != SearchCriteriaOp.EQ ||
            !is_direct_child (id)) {
            return yield base.search (expression,
                                      offset,
                                      max_count,
                                      out total_matches,
                                      cancellable);
        }

        var factory = new ExternalItemFactory ();

        if (ExternalItemFactory.id_valid (id)) {
            var media_object = yield factory.create_for_id (id, this);
            results.add (media_object);
        } else {
            foreach (var container in this.containers) {
                if (container.id == id) {
                    results.add (container);
                }
            }
        }

        total_matches = results.size;

        return results;
    }

    private bool is_direct_child (string id) {
        if (ExternalItemFactory.id_valid (id)) {
            return true;
        } else {
            foreach (var container in this.containers) {
                if (container.id == id) {
                    return true;
                }
            }

            return false;
        }
    }

    private void update_container () throws GLib.Error {
        this.containers.clear ();

        var obj_paths = this.actual_container.containers;
        foreach (var obj_path in obj_paths) {
            var container = new ExternalContainer (
                                        "container:" + (string) obj_path,
                                        this.service_name,
                                        obj_path,
                                        this.host_ip,
                                        this);
            this.containers.add (container);
        }

        this.child_count = this.containers.size +
                           this.actual_container.item_count;
    }

    private void on_updated (ExternalMediaContainer actual_container) {
        try {
            // Update our information about the container
            this.update_container ();
        } catch (GLib.Error err) {
            warning ("Failed to update information about container '%s': %s\n",
                     this.id,
                     err.message);
        }

        // and signal the clients
        this.updated ();
    }
}

