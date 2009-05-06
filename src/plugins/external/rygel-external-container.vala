/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
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

using Rygel;
using GUPnP;
using DBus;
using Gee;

/**
 * Represents and external container.
 */
public class Rygel.ExternalContainer : MediaContainer {
    // class-wide constants
    private static string PROPS_IFACE = "org.freedesktop.DBus.Properties";
    private const string OBJECT_IFACE = "org.Rygel.MediaObject1";
    private const string CONTAINER_IFACE = "org.Rygel.MediaContainer1";
    private const string ITEM_IFACE = "org.Rygel.MediaItem1";

    public dynamic DBus.Object actual_container;

    private string service_path;
    private string object_path;

    private ArrayList<MediaObject> media_objects;

    public ExternalContainer (string             id,
                              string             service_path,
                              string             object_path,
                              ExternalContainer? parent) {
        base (id, parent, "Uknown", 0);

        this.service_path = service_path;
        this.object_path = object_path;

        this.media_objects = new ArrayList<MediaObject> ();

        try {
            DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

            // Create proxy to MediaObject iface to get the display name through
            dynamic DBus.Object props = connection.get_object (service_path,
                                                               object_path,
                                                               PROPS_IFACE);
            Value value;
            props.Get (OBJECT_IFACE, "display-name", out value);
            this.title = value.get_string ();

            // Now proxy to MediaContainer iface for the rest of the stuff
            this.actual_container = connection.get_object (service_path,
                                                           object_path,
                                                           CONTAINER_IFACE);

            this.fetch_media_objects ();
        } catch (DBus.Error error) {
            critical ("Failed to fetch root media objects: %s\n",
                      error.message);
        }
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        var containers = this.media_objects.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>>
                                                (this, callback);
        res.data = containers;
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
        MediaObject media_object = find_object_sync (id);

        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        res.data = media_object;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<MediaObject>) res;
        return simple_res.data;
    }

    // Private methods
    private MediaObject? find_object_sync (string id) {
        MediaObject obj = null;

        foreach (var tmp in this.media_objects) {
            if (id == tmp.id) {
                obj = tmp;
            } else if (tmp is ExternalContainer) {
                // Check it's children
                var container = (ExternalContainer) tmp;

                obj = container.find_object_sync (id);
            }

            if (obj != null) {
                break;
            }
        }

        return obj;
    }

    private void fetch_media_objects () throws GLib.Error {
        string[] object_paths = null;

        object_paths = this.actual_container.GetContainers ();
        foreach (var object_path in object_paths) {
            this.media_objects.add (new ExternalContainer (object_path,
                                                           this.service_path,
                                                           object_path,
                                                           this));
        }

        object_paths = this.actual_container.GetItems ();
        foreach (var object_path in object_paths) {
            this.media_objects.add (new ExternalItem (this.service_path,
                                                      object_path,
                                                      this));
        }

        this.child_count = this.media_objects.size;
    }
}

