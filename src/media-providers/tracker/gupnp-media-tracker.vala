/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using GUPnP;
using DBus;

public class GUPnP.MediaTracker : MediaProvider {
    /* class-wide constants */
    public static const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    public static const string TRACKER_PATH = "/org/freedesktop/tracker";
    public static const string TRACKER_IFACE = "org.freedesktop.Tracker";
    public static const string FILES_IFACE = "org.freedesktop.Tracker.Files";
    public static const string METADATA_IFACE =
                                            "org.freedesktop.Tracker.Metadata";

    public static const int MAX_REQUESTED_COUNT = 128;

    private MediaContainer root_container;

    /* FIXME: Make this a static if you know how to initize it */
    private List<TrackerContainer> containers;

    private dynamic DBus.Object metadata;
    private dynamic DBus.Object files;
    private dynamic DBus.Object tracker;

    private SearchCriteriaParser search_parser;

    construct {
        this.root_container = new MediaContainer (this.root_id,
                                                  this.root_parent_id,
                                                  this.title,
                                                  this.containers.length ());

        this.containers = new List<TrackerContainer> ();
        this.containers.append
                        (new TrackerContainer (this.root_id + ":" + "16",
                                                this.root_id,
                                                "All Images",
                                                "Images",
                                                MediaItem.IMAGE_CLASS));
        this.containers.append
                        (new TrackerContainer (this.root_id + ":" + "14",
                                                this.root_id,
                                                "All Music",
                                                "Music",
                                                MediaItem.MUSIC_CLASS));
        this.containers.append
                        (new TrackerContainer (this.root_id + ":" + "15",
                                                this.root_id,
                                                "All Videos",
                                                "Videos",
                                                MediaItem.VIDEO_CLASS));

        this.search_parser = new SearchCriteriaParser ();

        DBus.Connection connection = DBus.Bus.get (DBus.BusType.SESSION);

        this.metadata = connection.get_object (MediaTracker.TRACKER_SERVICE,
                                               MediaTracker.TRACKER_PATH,
                                               MediaTracker.METADATA_IFACE);
        this.files = connection.get_object (MediaTracker.TRACKER_SERVICE,
                                            MediaTracker.TRACKER_PATH,
                                            MediaTracker.FILES_IFACE);
        this.tracker = connection.get_object (MediaTracker.TRACKER_SERVICE,
                                              MediaTracker.TRACKER_PATH,
                                              MediaTracker.TRACKER_IFACE);

        weak string home_dir = Environment.get_home_dir ();

        /* Host the home dir of the user */
        this.context.host_path (home_dir, home_dir);
    }

    /* Pubic methods */
    public MediaTracker (string        root_id,
                         string        root_parent_id,
                         GUPnP.Context context) {
        this.root_id = root_id;
        this.root_parent_id = root_parent_id;
        this.title = "Tracker";
        this.context = context;
    }

    public override void add_children_metadata
                            (DIDLLiteWriter didl_writer,
                             string         container_id,
                             string         filter,
                             uint           starting_index,
                             uint           requested_count,
                             string         sort_criteria,
                             out uint       number_returned,
                             out uint       total_matches,
                             out uint       update_id) throws GLib.Error {
        if (container_id == this.root_id) {
            number_returned = this.add_root_container_children (didl_writer);
            total_matches = number_returned;
        } else {
            TrackerContainer container;

            if (requested_count == 0)
                requested_count = MAX_REQUESTED_COUNT;

            container = this.find_container_by_id (container_id);
            if (container == null)
                number_returned = 0;
            else {
                number_returned =
                    this.add_container_children_from_db (didl_writer,
                                                         container,
                                                         starting_index,
                                                         requested_count,
                                                         out total_matches);
            }
        }

        if (number_returned > 0) {
            update_id = uint32.MAX;
        } else {
            throw new MediaProviderError.NO_SUCH_OBJECT ("No such object");
        }
    }

    public override void add_metadata
                            (DIDLLiteWriter didl_writer,
                             string         object_id,
                             string         filter,
                             string         sort_criteria,
                             out uint       update_id) throws GLib.Error {
        bool found = false;

        if (object_id == this.root_id) {
            this.root_container.serialize (didl_writer);

            found = true;
        } else {
            TrackerContainer container;

            /* First try containers */
            container = find_container_by_id (object_id);

            if (container != null) {
                add_container_from_db (didl_writer, container);

                found = true;
            } else {
                string id = this.remove_root_id_prefix (object_id);

                /* Now try items */
                container = get_item_parent (id);

                if (container != null)
                    found = add_item_from_db (didl_writer,
                                              container,
                                              id);
            }
        }

        if (!found) {
            throw new MediaProviderError.NO_SUCH_OBJECT ("No such object");
        }

        update_id = uint32.MAX;
    }

    /* Private methods */
    private uint add_root_container_children (DIDLLiteWriter didl_writer) {
        foreach (TrackerContainer container in this.containers)
            this.add_container_from_db (didl_writer, container);

        return this.containers.length ();
    }

    private void add_container_from_db (DIDLLiteWriter    didl_writer,
                                        TrackerContainer container) {
        /* Update the child count */
        container.child_count = get_container_children_count (container);

        container.serialize (didl_writer);
    }

    private uint get_container_children_count (TrackerContainer container) {
        string[][] stats;

        try {
                stats = this.tracker.GetStats ();
        } catch (GLib.Error error) {
            critical ("error getting tracker statistics: %s", error.message);

            return 0;
        }

        uint count = 0;
        for (uint i = 0; i < stats.length; i++) {
            if (stats[i][0] == container.tracker_category)
                count = stats[i][1].to_int ();
        }

        return count;
    }

    private TrackerContainer? find_container_by_id (string container_id) {
        TrackerContainer container;

        container = null;

        foreach (TrackerContainer tmp in this.containers)
            if (container_id == tmp.id) {
                container = tmp;

                break;
            }

        return container;
    }

    private uint add_container_children_from_db
                    (DIDLLiteWriter    didl_writer,
                     TrackerContainer container,
                     uint              offset,
                     uint              max_count,
                     out uint          child_count) {
        string[] children;

        children = this.get_container_children_from_db (container,
                                                        offset,
                                                        max_count,
                                                        out child_count);
        if (children == null)
            return 0;

        /* Iterate through all items */
        for (uint i = 0; i < children.length; i++)
            this.add_item_from_db (didl_writer,
                                   container,
                                   children[i]);

        return children.length;
    }

    private string[]? get_container_children_from_db
                            (TrackerContainer container,
                             uint              offset,
                             uint              max_count,
                             out uint          child_count) {
        string[] children = null;

        child_count = get_container_children_count (container);

        try {
            children = this.files.GetByServiceType (0,
                                                    container.tracker_category,
                                                    (int) offset,
                                                    (int) max_count);
        } catch (GLib.Error error) {
            critical ("error: %s", error.message);

            return null;
        }

        return children;
    }

    private bool add_item_from_db (DIDLLiteWriter    didl_writer,
                                   TrackerContainer parent,
                                   string            path) {
        if (parent.child_class == MediaItem.VIDEO_CLASS) {
            return this.add_video_item_from_db (didl_writer, parent, path);
        } else if (parent.child_class == MediaItem.IMAGE_CLASS) {
            return this.add_image_item_from_db (didl_writer, parent, path);
        } else {
            return this.add_music_item_from_db (didl_writer, parent, path);
        }
    }

    private bool add_video_item_from_db (DIDLLiteWriter    didl_writer,
                                         TrackerContainer parent,
                                         string            path) {
        string[] keys = new string[] {"File:Name",
                                      "File:Mime",
                                      "Video:Title",
                                      "Video:Author",
                                      "Video:Width",
                                      "Video:Height",
                                      "DC:Date"};

        string[] values = null;

        /* TODO: make this async */
        try {
            values = this.metadata.Get (parent.tracker_category, path, keys);
        } catch (GLib.Error error) {
            critical ("failed to get metadata for %s: %s\n",
                      path,
                      error.message);

            return false;
        }

        string title;
        if (values[2] != "")
            title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            title = values[0];

        MediaItem item = new MediaItem (this.root_id + ":" + path,
                                        parent.id,
                                        title,
                                        parent.child_class);

        if (values[4] != "")
            item.width = values[4].to_int ();

        if (values[5] != "")
            item.height = values[5].to_int ();

        item.date = seconds_to_iso8601 (values[6]);
        item.mime = values[1];
        item.author = values[3];
        item.uri = uri_from_path (path);

        item.serialize (didl_writer);

        return true;
    }

    private bool add_image_item_from_db (DIDLLiteWriter    didl_writer,
                                         TrackerContainer parent,
                                         string            path) {
        string[] keys = new string[] {"File:Name",
                                      "File:Mime",
                                      "Image:Title",
                                      "Image:Creator",
                                      "Image:Width",
                                      "Image:Height",
                                      "Image:Album",
                                      "Image:Date",
                                      "DC:Date"};

        string[] values = null;

        /* TODO: make this async */
        try {
            values = this.metadata.Get (parent.tracker_category, path, keys);
        } catch (GLib.Error error) {
            critical ("failed to get metadata for %s: %s\n",
                      path,
                      error.message);

            return false;
        }

        string title;
        if (values[2] != "")
            title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            title = values[0];

        MediaItem item = new MediaItem (this.root_id + ":" + path,
                                        parent.id,
                                        title,
                                        parent.child_class);

        if (values[4] != "")
            item.width = values[4].to_int ();

        if (values[5] != "")
            item.height = values[5].to_int ();

        if (values[8] != "") {
            item.date = seconds_to_iso8601 (values[8]);
        } else {
            item.date = seconds_to_iso8601 (values[7]);
        }

        item.mime = values[1];
        item.author = values[3];
        item.album = values[6];
        item.uri = uri_from_path (path);

        item.serialize (didl_writer);

        return true;
    }

    private bool add_music_item_from_db (DIDLLiteWriter   didl_writer,
                                        TrackerContainer parent,
                                         string           path) {
        string[] keys = new string[] {"File:Name",
                                      "File:Mime",
                                      "Audio:Title",
                                      "Audio:Artist",
                                      "Audio:TrackNo",
                                      "Audio:Album",
                                      "Audio:ReleaseDate",
                                      "Audio:DateAdded",
                                      "DC:Date"};

        string[] values = null;

        /* TODO: make this async */
        try {
            values = this.metadata.Get (parent.tracker_category, path, keys);
        } catch (GLib.Error error) {
            critical ("failed to get metadata for %s: %s\n",
                      path,
                      error.message);

            return false;
        }

        string title;
        if (values[2] != "")
            title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            title = values[0];

        MediaItem item = new MediaItem (this.root_id + ":" + path,
                                        parent.id,
                                        title,
                                        parent.child_class);

        if (values[4] != "")
            item.track_number = values[4].to_int ();

        if (values[8] != "") {
            item.date = seconds_to_iso8601 (values[8]);
        } else if (values[6] != "") {
            item.date = seconds_to_iso8601 (values[6]);
        } else {
            item.date = seconds_to_iso8601 (values[7]);
        }

        item.mime = values[1];
        item.author = values[3];
        item.album = values[5];
        item.uri = uri_from_path (path);

        item.serialize (didl_writer);

        return true;
    }

    private TrackerContainer? get_item_parent (string uri) {
        TrackerContainer container = null;
        string category;

        try {
            category = this.files.GetServiceType (uri);
        } catch (GLib.Error error) {
            critical ("failed to find service type for %s: %s",
                      uri,
                      error.message);

            return null;
        }

        foreach (TrackerContainer tmp in this.containers) {
            if (tmp.tracker_category == category) {
                container = tmp;

                break;
            }
        }

        return container;
    }

    string seconds_to_iso8601 (string seconds) {

        string date;

        if (seconds != "") {
            TimeVal tv;

            tv.tv_sec = seconds.to_int ();
            tv.tv_usec = 0;

            date = tv.to_iso8601 ();
        } else {
            date = "";
        }

        return date;
    }

    string remove_root_id_prefix (string id) {
        string[] tokens;

        tokens = id.split (":", 2);

        if (tokens[1] != null)
            return tokens[1];
        else
            return tokens[0];
    }

    private string uri_from_path (string path) {
        string escaped_path = Uri.escape_string (path, "/", true);

        return "http://%s:%u%s".printf (context.host_ip,
                                        context.port,
                                        escaped_path);
    }
}

[ModuleInit]
public MediaProvider register_media_provider (string        root_id,
                                              string        root_parent_id,
                                              GUPnP.Context context) {
    return new MediaTracker (root_id,
                             root_parent_id,
                             context);
}

