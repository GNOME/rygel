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
public abstract class Rygel.TrackerCategory : MediaContainer {
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

    Gee.List<AsyncResult> results;

    public TrackerCategory (string         id,
                            MediaContainer parent,
                            string         title,
                            string         category,
                            string         child_class) {
        base (id, parent, title, 0);

        this.category = category;
        this.child_class = child_class;

        try {
            this.create_proxies ();

            /* FIXME: We need to hook to some tracker signals to keep
             *        this field up2date at all times
             */
            this.get_children_count ();

            this.results = new Gee.ArrayList<AsyncResult>();
        } catch (DBus.Error error) {
            critical ("Failed to create to Session bus: %s\n",
                      error.message);
        }
    }

    private void get_children_count () {
        try {
            // We are performing actual search (though an optimized one) to get
            // the hitcount rather than GetHitCount because GetHitCount only
            // allows us to get hit count for Text searches.
            this.search.Query (0,
                               this.category,
                               new string[0],
                               "",
                               new string[0],
                               "",
                               false,
                               new string[0],
                               false,
                               0,
                               -1,
                               on_search_query_cb);
        } catch (GLib.Error error) {
            critical ("error getting items under category '%s': %s",
                      this.category,
                      error.message);

            return;
        }
    }

    private void on_search_query_cb (string[][] search_result,
                                     GLib.Error error) {
        if (error != null) {
            critical ("error getting items under category '%s': %s",
                      this.category,
                      error.message);

            return;
        }

        this.child_count = search_result.length;
        this.updated ();
    }

    public override void get_children (uint               offset,
                                       uint               max_count,
                                       Cancellable?       cancellable,
                                       AsyncReadyCallback callback) {
        var res = new TrackerSearchResult (this, callback);

        this.results.add (res);

        try {
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
        } catch (GLib.Error error) {
            res.error = error;

            res.complete_in_idle ();
        }
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
        var res = new TrackerGetMetadataResult (this, callback, id);

        this.results.add (res);

        try {
            string path = this.get_item_path (id);
            if (path == null) {
                throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                                    "No such object");
            }

            string[] keys = this.get_metadata_keys ();

            this.metadata.Get (this.category, path, keys, res.ready);
        } catch (GLib.Error error) {
            res.error = error;

            res.complete_in_idle ();
        }
    }

    public override MediaObject? find_object_finish (AsyncResult res)
                                                     throws GLib.Error {
        var metadata_res = (TrackerGetMetadataResult) res;

        if (metadata_res.error != null) {
            throw metadata_res.error;
        } else {
            return metadata_res.data;
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

    public string? get_item_path (string item_id) {
        var tokens = item_id.split (":", 2);

        if (tokens[0] != null && tokens[1] != null) {
            return tokens[1];
        } else {
            return null;
        }
    }

    private void create_proxies () throws GLib.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.metadata = connection.get_object (TrackerCategory.TRACKER_SERVICE,
                                               TrackerCategory.METADATA_PATH,
                                               TrackerCategory.METADATA_IFACE);
        this.search = connection.get_object (TrackerCategory.TRACKER_SERVICE,
                                             TrackerCategory.SEARCH_PATH,
                                             TrackerCategory.SEARCH_IFACE);
        this.tracker = connection.get_object (TrackerCategory.TRACKER_SERVICE,
                                              TrackerCategory.TRACKER_PATH,
                                              TrackerCategory.TRACKER_IFACE);
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
    protected abstract MediaItem? create_item (string path, string[] metadata);
}

