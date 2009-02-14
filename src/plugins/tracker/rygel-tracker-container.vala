/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * Represents Tracker category.
 */
public class Rygel.TrackerContainer : MediaContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    private const string TRACKER_PATH = "/org/freedesktop/Tracker";
    private const string TRACKER_IFACE = "org.freedesktop.Tracker";
    private const string FILES_PATH = "/org/freedesktop/Tracker/Files";
    private const string FILES_IFACE = "org.freedesktop.Tracker.Files";
    private const string METADATA_PATH = "/org/freedesktop/Tracker/Metadata";
    private const string METADATA_IFACE = "org.freedesktop.Tracker.Metadata";

    public static dynamic DBus.Object metadata;
    public static dynamic DBus.Object files;
    public static dynamic DBus.Object tracker;

    public string category;

    /* UPnP class of items under this container */
    public string child_class;

    // Class constructor
    static construct {
        DBus.Connection connection;
        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error error) {
            critical ("Failed to connect to Session bus: %s\n",
                      error.message);
        }

        TrackerContainer.metadata =
                    connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                           TrackerContainer.METADATA_PATH,
                                           TrackerContainer.METADATA_IFACE);
        TrackerContainer.files =
                    connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                           TrackerContainer.FILES_PATH,
                                           TrackerContainer.FILES_IFACE);
        TrackerContainer.tracker =
                    connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                           TrackerContainer.TRACKER_PATH,
                                           TrackerContainer.TRACKER_IFACE);
    }

    public TrackerContainer (string id,
                             string parent_id,
                             string title,
                             string category,
                             string child_class) {
        base (id, parent_id, title, 0);

        this.category = category;
        this.child_class = child_class;

        /* FIXME: We need to hook to some tracker signals to keep
         *        this field up2date at all times
         */
        this.child_count = this.get_children_count ();
    }

    private uint get_children_count () {
        string[][] stats;

        try {
                stats = TrackerContainer.tracker.GetStats ();
        } catch (GLib.Error error) {
            critical ("error getting tracker statistics: %s", error.message);

            return 0;
        }

        uint count = 0;
        for (uint i = 0; i < stats.length; i++) {
            if (stats[i][0] == this.category)
                count = stats[i][1].to_int ();
        }

        return count;
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<Gee.List<MediaObject>> (
                                                this,
                                                callback);

        try {
            string[] child_paths;

            child_paths = TrackerContainer.files.GetByServiceType (
                                                        0,
                                                        this.category,
                                                        (int) offset,
                                                        (int) max_count);

            ArrayList<MediaObject> children = new ArrayList<MediaObject> ();

            /* Iterate through all items */
            for (uint i = 0; i < child_paths.length; i++) {
                MediaObject item = this.find_item_by_path (child_paths[i]);
                children.add (item);
            }

            res.data = children;
        } catch (GLib.Error error) {
            res.error = error;
        }

        res.complete_in_idle ();
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                         AsyncResult res)
                                                         throws GLib.Error {
        var simple_res = (Rygel.SimpleAsyncResult<Gee.List<MediaObject>>) res;

        if (simple_res.error != null) {
            throw simple_res.error;
        } else {
            return simple_res.data;
        }
    }

    public MediaItem? find_item (string id) throws GLib.Error {
        string path = this.get_item_path (id);

        if (path == null) {
            return null;
        }

        return this.find_item_by_path (path);
    }

    public MediaItem? find_item_by_path (string path) throws GLib.Error {
        MediaItem item;

        if (this.child_class == MediaItem.VIDEO_CLASS) {
            item = new TrackerVideoItem (this.id + ":" + path, path, this);
        } else if (this.child_class == MediaItem.IMAGE_CLASS) {
            item = new TrackerImageItem (this.id + ":" + path, path, this);
        } else {
            item = new TrackerMusicItem (this.id + ":" + path, path, this);
        }

        return item;
    }

    public override void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        try {
            res.data = this.find_item (id);
        } catch (GLib.Error error) {
            res.error = error;
        }

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

    public bool is_thy_child (string item_id) {
        var parent_id = this.get_item_parent_id (item_id);

        if (parent_id != null && parent_id == this.id) {
            return true;
        } else {
            return false;
        }
    }

    private string? get_item_path (string item_id) {
        var tokens = item_id.split (":", 2);

        if (tokens[0] != null && tokens[1] != null) {
            return tokens[1];
        } else {
            return null;
        }
    }

    private string? get_item_parent_id (string item_id) {
        var tokens = item_id.split (":", 2);

        if (tokens[0] != null) {
            return tokens[0];
        } else {
            return null;
        }
    }
}

