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
    // class-wide constants
    private static string PROPS_IFACE = "org.freedesktop.DBus.Properties";
    private const string OBJECT_IFACE = "org.gnome.UPnP.MediaObject1";
    private const string CONTAINER_IFACE = "org.gnome.UPnP.MediaContainer1";
    private const string ITEM_IFACE = "org.gnome.UPnP.MediaItem1";

    public dynamic DBus.Object actual_container;
    public dynamic DBus.Object props;

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

            // Create proxy to MediaObject iface to get the display name through
            this.props = connection.get_object (service_name,
                                                object_path,
                                                PROPS_IFACE);
            Value value;
            this.props.Get (OBJECT_IFACE, "DisplayName", out value);
            this.title = this.substitute_keywords (value.get_string ());

            // Now proxy to MediaContainer iface for the rest of the stuff
            this.actual_container = connection.get_object (service_name,
                                                           object_path,
                                                           CONTAINER_IFACE);

            this.update_container ();

            this.actual_container.Updated += this.on_container_updated;
        } catch (GLib.Error err) {
            critical ("Failed to fetch information about container '%s': %s\n",
                      this.id,
                      err.message);
        }
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        var media_objects = new ArrayList <MediaObject> ();

        // First add the child containers
        media_objects.add_all (this.containers);

        // Then get and add the child items
        Value value;
        this.props.Get (CONTAINER_IFACE, "Items", out value);

        unowned PtrArray obj_paths = (PtrArray) value.get_boxed ();
        if (obj_paths.len > 0) {
            for (var i = 0; i < obj_paths.len; i++) {
                var obj_path = (ObjectPath) obj_paths.pdata[i];

                try {
                    var item = new ExternalItem.for_path (obj_path, this);

                    media_objects.add (item);
                } catch (GLib.Error err) {
                    warning ("Error initializable item at '%s': %s. Ignoring..",
                             obj_path,
                             err.message);
                }
            }
        }

        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);

        var children = media_objects.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>>
                                                (this, callback);
        res.data = children;
        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                         AsyncResult res)
                                                         throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;
        return simple_res.data;
    }

    public override void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        MediaObject media_object = find_container (id);
        if (media_object == null && ExternalItem.id_valid (id)) {
            try {
                media_object = new ExternalItem.for_id (id, this);
            } catch (GLib.Error err) {
                res.error = err;
            }
        }

        res.data = media_object;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<MediaObject>) res;

        if (simple_res.error != null) {
            throw simple_res.error;
        } else {
            return simple_res.data;
        }
    }

    public string substitute_keywords (string title) {
        var new_title = title.replace ("@REALNAME@",
                                       Environment.get_real_name ());
        new_title = new_title.replace ("@USERNAME@",
                                       Environment.get_user_name ());
        new_title = new_title.replace ("@HOSTNAME@",
                                       Environment.get_host_name ());

        return new_title;
    }

    // Private methods
    private MediaContainer? find_container (string id) {
        MediaContainer container = null;

        foreach (var tmp in this.containers) {
            if (id == tmp.id) {
                container = tmp;
            } else {
                // Check it's children
                container = tmp.find_container (id);
            }

            if (container != null) {
                break;
            }
        }

        return container;
    }

    private void update_container () throws GLib.Error {
        this.containers.clear ();

        Value value;
        this.props.Get (CONTAINER_IFACE, "Containers", out value);

        unowned PtrArray obj_paths = (PtrArray) value.get_boxed ();
        if (obj_paths.len > 0) {
            for (var i = 0; i < obj_paths.len; i++) {
                var obj_path = (ObjectPath) obj_paths.pdata[i];
                var container = new ExternalContainer (
                                        "container:" + (string) obj_path,
                                        this.service_name,
                                        obj_path,
                                        this.host_ip,
                                        this);
                this.containers.add (container);
            }
        }

        this.child_count = this.containers.size;
        this.props.Get (CONTAINER_IFACE, "ItemCount", out value);
        this.child_count += value.get_uint ();
    }

    private void on_container_updated (dynamic DBus.Object actual_container) {
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

