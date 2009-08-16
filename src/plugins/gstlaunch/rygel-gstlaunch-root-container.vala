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
    static const string GSTLAUNCH_FILE = "rygel-gstlaunch.conf";
    ArrayList<MediaItem> items;
    KeyFile key_file;

    public GstLaunchRootContainer (string title) {
        base.root (title, 0);

        this.items = new ArrayList<MediaItem> ();

        try {
          load_key_file ();
          parse_key_file ();
        } catch (Error err) {
          debug ("GstLaunch init failed: %s", err.message);
        }

        this.child_count = this.items.size;
    }

    void load_key_file () throws Error {
      this.key_file = new KeyFile ();

      var dirs = new string[2];
      dirs[0] = Environment.get_user_config_dir ();
      dirs[1] = BuildConfig.SYS_CONFIG_DIR;

      string path;
      this.key_file.load_from_dirs (GSTLAUNCH_FILE,
                                    dirs,
                                    out path,
                                    KeyFileFlags.KEEP_COMMENTS |
                                    KeyFileFlags.KEEP_TRANSLATIONS);
      debug ("Loaded gstlaunch configuration from file '%s'", path);
    }

    void parse_key_file () throws Error {
      var items = this.key_file.get_groups ();
      foreach (string item in items) {
        debug ("found item: %s", item);
        string title = this.key_file.get_string (item, "title");
        string mime_type = this.key_file.get_string (item, "mime");
        string launch_line = this.key_file.get_string (item, "launch");

        this.items.add (new GstLaunchItem (item, this, title, mime_type, launch_line));
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

