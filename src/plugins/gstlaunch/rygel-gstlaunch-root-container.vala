/*
 * Copyright (C) 2009 Thijs Vermeir <thijsvermeir@gmail.com>
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
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
using Gee;
using Gst;
using CStuff;

/**
 * Represents the root container for GstLaunch content hierarchy.
 */
public class Rygel.GstLaunchRootContainer : MediaContainer {
    const string CONFIG_GROUP = "GstLaunch";
    const string ITEM_NAMES = "launch_items";

    ArrayList<MediaItem> items;
    MetaConfig config;

    public GstLaunchRootContainer (string title) {
        base.root (title, 0);

        this.items = new ArrayList<MediaItem> ();

        try {
          config = MetaConfig.get_default ();
          var item_names = config.get_string_list (CONFIG_GROUP, ITEM_NAMES);
          foreach (string name in item_names)
            add_launch_item (name);
        } catch (Error err) {
          debug ("GstLaunch init failed: %s", err.message);
        }

        this.child_count = this.items.size;
    }

    void add_launch_item (string name) {
      try {
        string title = config.get_string (CONFIG_GROUP, "%s_title".printf (name));
        string mime_type = config.get_string (CONFIG_GROUP, "%s_mime".printf (name));
        string launch_line = config.get_string (CONFIG_GROUP, "%s_launch".printf (name));
        this.items.add (new GstLaunchItem (name, this, title, mime_type, launch_line));
      } catch (GLib.Error err) {
        debug ("GstLaunch failed item '%s': %s", name, err.message);
      }
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        var children = this.items.slice ((int) offset, (int) stop);

        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>>
                                            (this,
                                             callback);
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
        var res = new Rygel.SimpleAsyncResult<string> (this, callback);

        res.data = id;
        res.complete_in_idle ();
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws Error {
        MediaItem item = null;
        var id = ((Rygel.SimpleAsyncResult<string>) res).data;

        foreach (MediaItem tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;

                break;
            }
        }

        return item;
    }
}

