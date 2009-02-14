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
public abstract class Rygel.TrackerContainer : MediaContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    private const string TRACKER_PATH = "/org/freedesktop/Tracker";
    private const string TRACKER_IFACE = "org.freedesktop.Tracker";
    private const string SEARCH_PATH = "/org/freedesktop/Tracker/Search";
    private const string SEARCH_IFACE = "org.freedesktop.Tracker.Search";
    private const string METADATA_PATH = "/org/freedesktop/Tracker/Metadata";
    private const string METADATA_IFACE = "org.freedesktop.Tracker.Metadata";

    public dynamic DBus.Object metadata;
    public dynamic DBus.Object search;
    public dynamic DBus.Object tracker;

    public string category;

    /* UPnP class of items under this container */
    public string child_class;

    Gee.List<TrackerSearchResult> results;

    public TrackerContainer (string id,
                             string parent_id,
                             string title,
                             string category,
                             string child_class) {
        base (id, parent_id, title, 0);

        this.category = category;
        this.child_class = child_class;

        DBus.Connection connection;
        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error error) {
            critical ("Failed to connect to Session bus: %s\n",
                      error.message);
            return;
        }

        this.metadata = connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                               TrackerContainer.METADATA_PATH,
                                               TrackerContainer.METADATA_IFACE);
        this.search = connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                             TrackerContainer.SEARCH_PATH,
                                             TrackerContainer.SEARCH_IFACE);
        this.tracker = connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                              TrackerContainer.TRACKER_PATH,
                                              TrackerContainer.TRACKER_IFACE);

        /* FIXME: We need to hook to some tracker signals to keep
         *        this field up2date at all times
         */
        this.child_count = this.get_children_count ();


        this.results = new Gee.ArrayList<TrackerSearchResult>();
    }

    private uint get_children_count () {
        string[][] search_result;

        try {
            search_result = this.search.Query (0,
                                               this.category,
                                               new string[0],
                                               "",
                                               new string[0],
                                               "",
                                               false,
                                               new string[0],
                                               false,
                                               0,
                                               -1);
        } catch (GLib.Error error) {
            critical ("error getting items under category '%s': %s",
                      this.category,
                      error.message);

            return 0;
        }

        return search_result.length;
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        var res = new TrackerSearchResult (this, callback);

        this.results.add (res);

        this.search.Query (0,
                           this.category,
                           this.get_metadata_keys (),
                           "",
                           new string[0],
                           "",
                           false,
                           new string[0],
                           false,
                           (int) offset,
                           (int) max_count,
                           res.ready);
    }

    public override Gee.List<MediaObject>? get_children_finish (
                                                         AsyncResult res)
                                                         throws GLib.Error {
        var search_res = (Rygel.TrackerSearchResult) res;

        this.results.remove (search_res);

        if (search_res.error != null) {
            throw search_res.error;
        } else {
            return search_res.data;
        }
    }

    public override void find_object (string             id,
                                      Cancellable?       cancellable,
                                      AsyncReadyCallback callback) {
        var res = new Rygel.SimpleAsyncResult<MediaObject> (this, callback);

        string path = this.get_item_path (id);
        if (path == null) {
            res.error = new ContentDirectoryError.NO_SUCH_OBJECT (
                                                    "No such object");
            res.complete_in_idle ();
            return;
        }

        try {
            string[] keys = this.get_metadata_keys ();
            string[] metadata = this.metadata.Get (this.category, path, keys);

            res.data = this.fetch_item_by_path (path, metadata);
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

    protected abstract string[] get_metadata_keys ();
    protected abstract MediaItem? fetch_item_by_path (string   path,
                                                      string[] metadata);
}

