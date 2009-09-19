/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
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

using GUPnP;
using DBus;
using Gee;

/**
 * A container listing a Tracker search result.
 */
public class Rygel.TrackerSearchContainer : Rygel.MediaContainer {
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

    public string service;

    public string query_condition;

    Gee.List<AsyncResult> results;

    public TrackerSearchContainer (string         id,
                                   MediaContainer parent,
                                   string         title,
                                   string         service,
                                   string?        query_condition) {
        base (id, parent, title, 0);

        this.service = service;

        if (query_condition != null) {
            this.query_condition = query_condition;
        } else {
            this.query_condition = "";
        }

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
                               this.service,
                               new string[0],
                               "",
                               new string[0],
                               this.query_condition,
                               false,
                               new string[0],
                               false,
                               0,
                               -1,
                               on_search_query_cb);
        } catch (GLib.Error error) {
            critical ("error getting items under service '%s': %s",
                      this.service,
                      error.message);

            return;
        }
    }

    private void on_search_query_cb (string[][] search_result,
                                     GLib.Error error) {
        if (error != null) {
            critical ("error getting items under service '%s': %s",
                      this.service,
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
                               this.service,
                               TrackerItem.get_metadata_keys (),
                               "",
                               new string[0],
                               this.query_condition,
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
            string parent_id;

            res.item_path = this.get_item_info (id,
                                                out parent_id,
                                                out res.item_service);
            if (res.item_path == null) {
                res.complete_in_idle ();
            }

            string[] keys = TrackerItem.get_metadata_keys ();

            this.metadata.Get (res.item_service,
                               res.item_path,
                               keys,
                               res.ready);
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
        string parent_id = null;
        this.get_item_info (id, out parent_id, out service);

        if (parent_id != null && parent_id == this.id) {
            return true;
        } else {
            return false;
        }
    }

    public MediaItem? create_item (string   service,
                                   string   path,
                                   string[] metadata) {
        var id = service + ":" + this.id + ":" + path;

        if (service == TrackerVideoItem.SERVICE) {
            return new TrackerVideoItem (id,
                                         path,
                                         this,
                                         metadata);
        } else if (service == TrackerImageItem.SERVICE) {
            return new TrackerImageItem (id,
                                         path,
                                         this,
                                         metadata);
        } else if (service == TrackerMusicItem.SERVICE) {
            return new TrackerMusicItem (id,
                                         path,
                                         this,
                                         metadata);
        } else {
            return null;
        }
    }

    // Returns the path, ID of the parent and service this item belongs to, or
    // null item_id is invalid
    public string? get_item_info (string     item_id,
                                  out string parent_id,
                                  out string service) {
        var tokens = item_id.split (":", 3);

        if (tokens[0] != null && tokens[1] != null && tokens[2] != null) {
            service = tokens[0];
            parent_id = tokens[1];

            return tokens[2];
        } else {
            return null;
        }
    }

    private void create_proxies () throws GLib.Error {
        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.metadata = connection.get_object (TRACKER_SERVICE,
                                               METADATA_PATH,
                                               METADATA_IFACE);
        this.search = connection.get_object (TRACKER_SERVICE,
                                             SEARCH_PATH,
                                             SEARCH_IFACE);
        this.tracker = connection.get_object (TRACKER_SERVICE,
                                              TRACKER_PATH,
                                              TRACKER_IFACE);
    }
}

