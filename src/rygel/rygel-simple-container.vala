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

using Gee;

/**
 * A simple implementation of MediaContainer that keeps all MediaObjects
 * in memory. In order for it to be of any use, you must add children to
 * children ArrayList field.
 */
public class Rygel.SimpleContainer : Rygel.MediaContainer {
    public ArrayList<MediaObject> children;

    private ArrayList<MediaObjectSearch> searches;

    public SimpleContainer (string          id,
                            MediaContainer? parent,
                            string          title) {
        base (id, parent, title, 0);

        this.children = new ArrayList<MediaObject> ();
        this.searches = new ArrayList<MediaObjectSearch> ();
    }

    public SimpleContainer.root (string title) {
        this ("0", null, title);
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);

        var media_objects = this.children.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>>
                                                (this, callback);
        res.data = media_objects;
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

        MediaObject child = null;

        foreach (var tmp in this.children) {
            if (id == tmp.id) {
                child = tmp;

                break;
            }
        }

        if (child != null) {
            res.data = child;
            res.complete_in_idle ();
        } else {
            var containers = new ArrayList<MediaContainer> ();

            foreach (var tmp in this.children) {
                if (tmp is MediaContainer) {
                    containers.add (tmp as MediaContainer);
                }
            }

            var search = new MediaObjectSearch
                                        <Rygel.SimpleAsyncResult<MediaObject>> (
                                        id,
                                        containers,
                                        res,
                                        cancellable);
            search.completed.connect (this.on_object_search_completed);

            this.searches.add (search);

            search.run ();
        }
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

    private void on_object_search_completed (StateMachine state_machine) {
        var search = state_machine as
                     MediaObjectSearch<Rygel.SimpleAsyncResult<MediaObject>>;

        search.data.data = search.media_object;
        search.data.error = search.error;
        search.data.complete ();

        this.searches.remove (search);
    }
}
