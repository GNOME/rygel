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

    public override Gee.List<MediaObject>? get_children (uint offset,
                                                         uint max_count)
                                                         throws GLib.Error {
        ArrayList<MediaObject> children = new ArrayList<MediaObject> ();

        string[] child_paths =
                TrackerContainer.files.GetByServiceType (0,
                                                         this.category,
                                                         (int) offset,
                                                         (int) max_count);

        /* Iterate through all items */
        for (uint i = 0; i < child_paths.length; i++) {
            MediaObject item = this.find_object (child_paths[i]);
            children.add (item);
        }

        return children;
    }

    public static string get_file_category (string uri) throws GLib.Error {
        string category;

        category = TrackerContainer.files.GetServiceType (uri);

        return category;
    }

    public override MediaObject? find_object (string id) throws GLib.Error {
        MediaObject item;
        string path = id;

        if (this.child_class == MediaItem.VIDEO_CLASS) {
            item = new TrackerVideoItem (path, path, this);
        } else if (this.child_class == MediaItem.IMAGE_CLASS) {
            item = new TrackerImageItem (path, path, this);
        } else {
            item = new TrackerMusicItem (path, path, this);
        }

        return item;
    }
}

