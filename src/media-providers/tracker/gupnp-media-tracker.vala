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

private class Tracker.Container {
    public string id;
    public string title;
    public string tracker_category;

    /* UPnP class of items under this container */
    public string child_class;

    public Container (string id,
                      string title,
                      string tracker_category,
                      string child_class) {
        this.id = id;
        this.title = title;
        this.tracker_category = tracker_category;
        this.child_class = child_class;
    }
}

public class GUPnP.MediaTracker : MediaProvider {
    /* class-wide constants */
    public static const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    public static const string TRACKER_PATH = "/org/freedesktop/tracker";
    public static const string TRACKER_IFACE = "org.freedesktop.Tracker";
    public static const string FILES_IFACE = "org.freedesktop.Tracker.Files";
    public static const string METADATA_IFACE =
                                            "org.freedesktop.Tracker.Metadata";

    public static const int MAX_REQUESTED_COUNT = 128;

    public static const string IMAGE_CLASS = "object.item.imageItem";
    public static const string VIDEO_CLASS = "object.item.videoItem";
    public static const string MUSIC_CLASS = "object.item.audioItem.musicTrack";

    /* FIXME: Make this a static if you know how to initize it */
    private List<Tracker.Container> containers;

    private dynamic DBus.Object metadata;
    private dynamic DBus.Object files;
    private dynamic DBus.Object tracker;

    private DIDLLiteWriter didl_writer;
    private SearchCriteriaParser search_parser;

    construct {
        this.containers = new List<Tracker.Container> ();
        this.containers.append
                        (new Tracker.Container ("16",
                                                "All Images",
                                                "Images",
                                                MediaTracker.IMAGE_CLASS));
        this.containers.append
                        (new Tracker.Container ("14",
                                                "All Music",
                                                "Music",
                                                MediaTracker.MUSIC_CLASS));
        this.containers.append
                        (new Tracker.Container ("15",
                                                "All Videos",
                                                "Videos",
                                                MediaTracker.VIDEO_CLASS));

        this.didl_writer = new DIDLLiteWriter ();
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

    public override string? browse (string   container_id,
                                    string   filter,
                                    uint     starting_index,
                                    uint     requested_count,
                                    string   sort_criteria,
                                    out uint number_returned,
                                    out uint total_matches,
                                    out uint update_id) {
        string didl;

        /* Start DIDL-Lite fragment */
        this.didl_writer.start_didl_lite (null, null, true);

        string id = this.remove_root_id_prefix (container_id);

        if (id == this.root_id) {
            number_returned = this.add_root_container_children ();
            total_matches = number_returned;
        } else {
            Tracker.Container container;

            if (requested_count == 0)
                requested_count = MAX_REQUESTED_COUNT;

            container = this.find_container_by_id (id);
            if (container == null)
                number_returned = 0;
            else {
                number_returned =
                    this.add_container_children_from_db (container,
                            starting_index,
                            requested_count,
                            out total_matches);
            }
        }

        if (number_returned > 0) {
            /* End DIDL-Lite fragment */
            this.didl_writer.end_didl_lite ();

            /* Retrieve generated string */
            didl = this.didl_writer.get_string ();

            update_id = uint32.MAX;
        } else
            didl = null;

        /* Reset the parser state */
        this.didl_writer.reset ();

        return didl;
    }

    public override string get_metadata (string  object_id,
                                         string  filter,
                                         string  sort_criteria,
                                         out uint update_id) {
        string didl;
        bool found;

        /* Start DIDL-Lite fragment */
        this.didl_writer.start_didl_lite (null, null, true);
        found = false;

        string id = this.remove_root_id_prefix (object_id);

        if (id == this.root_id) {
            add_root_container ();

            found = true;
        } else {
            Tracker.Container container;

            /* First try containers */
            container = find_container_by_id (id);

            if (container != null) {
                add_container_from_db (container, this.root_id);

                found = true;
            } else {
                /* Now try items */
                container = get_item_parent (id);

                if (container != null)
                    found = add_item_from_db (container, id);
            }
        }

        if (found) {
            /* End DIDL-Lite fragment */
            this.didl_writer.end_didl_lite ();

            /* Retrieve generated string */
            didl = this.didl_writer.get_string ();
        } else
            didl = null;

        /* Reset the parser state */
        this.didl_writer.reset ();

        update_id = uint32.MAX;

        return didl;
    }

    public override uint get_root_children_count () {
        return this.containers.length ();
    }

    /* Private methods */
    private uint add_root_container_children () {
        foreach (Tracker.Container container in this.containers)
            this.add_container_from_db (container, this.root_id);

        return this.get_root_children_count ();
    }

    private void add_container_from_db (Tracker.Container container,
                                        string            parent_id) {
        uint child_count;

        child_count = get_container_children_count (container);

        this.add_container (container.id,
                            parent_id,
                            container.title,
                            child_count);
    }

    private void add_container (string id,
                                string parent_id,
                                string title,
                                uint   child_count) {
        string exported_id, exported_parent_id;

        if (id == this.root_id)
            exported_id = id;
        else
            exported_id = this.root_id + ":" + id;

        if (parent_id == this.root_id || parent_id == this.root_parent_id)
            exported_parent_id = parent_id;
        else
            exported_parent_id = this.root_id + ":" + parent_id;

        this.didl_writer.start_container (exported_id,
                                          exported_parent_id,
                                          (int) child_count,
                                          false,
                                          false);

        this.didl_writer.add_string ("class",
                                     DIDLLiteWriter.NAMESPACE_UPNP,
                                     null,
                                     "object.container.storageFolder");

        this.didl_writer.add_string ("title",
                                     DIDLLiteWriter.NAMESPACE_DC,
                                     null,
                                     title);

        /* End of Container */
        this.didl_writer.end_container ();
    }

    private uint get_container_children_count (Tracker.Container container) {
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

    private Tracker.Container? find_container_by_id (string container_id) {
        Tracker.Container container;

        container = null;

        foreach (Tracker.Container tmp in this.containers)
            if (container_id == tmp.id) {
                container = tmp;

                break;
            }

        return container;
    }

    private uint add_container_children_from_db
                    (Tracker.Container container,
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
            this.add_item_from_db (container, children[i]);

        return children.length;
    }

    private string[]? get_container_children_from_db
                            (Tracker.Container container,
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

    private bool add_item_from_db (Tracker.Container parent,
                                   string            path) {
        if (parent.child_class == VIDEO_CLASS) {
            return this.add_video_item_from_db (parent, path);
        } else if (parent.child_class == IMAGE_CLASS) {
            return this.add_image_item_from_db (parent, path);
        } else {
            return this.add_music_item_from_db (parent, path);
        }
    }

    private bool add_video_item_from_db (Tracker.Container parent,
                                         string path) {
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

        int width = -1;
        int height = -1;

        if (values[4] != "")
            width = values[4].to_int ();

        if (values[5] != "")
            height = values[5].to_int ();

        string title;
        if (values[2] != "")
            title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            title = values[0];

        string date = seconds_to_iso8601 (values[6]);

        this.add_item (path,
                       parent.id,
                       values[1],
                       title,
                       values[3],
                       "",
                       date,
                       parent.child_class,
                       width,
                       height,
                       -1,
                       path);

        return true;
    }

    private bool add_image_item_from_db (Tracker.Container parent,
                                         string path) {
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

        int width = -1;
        int height = -1;

        if (values[4] != "")
            width = values[4].to_int ();

        if (values[5] != "")
            height = values[5].to_int ();

        string title;
        if (values[2] != "")
            title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            title = values[0];

        string seconds;

        if (values[8] != "") {
            seconds = values[8];
        } else {
            seconds = values[7];
        }

        string date = seconds_to_iso8601 (seconds);

        this.add_item (path,
                       parent.id,
                       values[1],
                       title,
                       values[3],
                       values[6],
                       date,
                       parent.child_class,
                       width,
                       height,
                       -1,
                       path);

        return true;
    }

    private bool add_music_item_from_db (Tracker.Container parent,
                                         string            path) {
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

        int track_number = -1;

        if (values[4] != "")
            track_number = values[4].to_int ();

        string title;
        if (values[2] != "")
            title = values[2];
        else
            /* If title wasn't provided, use filename instead */
            title = values[0];

        string seconds;

        if (values[8] != "") {
            seconds = values[8];
        } else if (values[6] != "") {
            seconds = values[6];
        } else {
            seconds = values[7];
        }

        string date = seconds_to_iso8601 (seconds);

        this.add_item (path,
                       parent.id,
                       values[1],
                       title,
                       values[3],
                       values[5],
                       date,
                       parent.child_class,
                       -1,
                       -1,
                       track_number,
                       path);

        return true;
    }

    private void add_item (string id,
                           string parent_id,
                           string mime,
                           string title,
                           string author,
                           string album,
                           string date,
                           string upnp_class,
                           int    width,
                           int    height,
                           int    track_number,
                           string path) {
        string exported_parent_id;
        if (parent_id == this.root_id)
            exported_parent_id = parent_id;
        else
            exported_parent_id = this.root_id + ":" + parent_id;

        this.didl_writer.start_item (this.root_id + ":" + id,
                                     exported_parent_id,
                                     null,
                                     false);

        /* Add fields */
        this.didl_writer.add_string ("title",
                                     DIDLLiteWriter.NAMESPACE_DC,
                                     null,
                                     title);

        this.didl_writer.add_string ("class",
                                     DIDLLiteWriter.NAMESPACE_UPNP,
                                     null,
                                     upnp_class);

        if (author != "") {
            this.didl_writer.add_string ("creator",
                                         DIDLLiteWriter.NAMESPACE_DC,
                                         null,
                                         author);

            if (upnp_class == VIDEO_CLASS) {
                this.didl_writer.add_string ("author",
                                             DIDLLiteWriter.NAMESPACE_UPNP,
                                             null,
                                             author);
            } else if (upnp_class == MUSIC_CLASS) {
                this.didl_writer.add_string ("artist",
                                             DIDLLiteWriter.NAMESPACE_UPNP,
                                             null,
                                             author);
            }
        }

        if (track_number >= 0) {
            this.didl_writer.add_int ("originalTrackNumber",
                                      DIDLLiteWriter.NAMESPACE_UPNP,
                                      null,
                                      track_number);
        }

        if (album != "") {
            this.didl_writer.add_string ("album",
                                         DIDLLiteWriter.NAMESPACE_UPNP,
                                         null,
                                         album);
        }

        if (date != "") {
            this.didl_writer.add_string ("date",
                                         DIDLLiteWriter.NAMESPACE_DC,
                                         null,
                                         date);
        }

        /* Add resource data */
        DIDLLiteResource res;

        /* URI */
        string escaped_path = Uri.escape_string (path, "/", true);
        string uri = "http://%s:%u%s".printf (context.host_ip,
                                              context.port,
                                              escaped_path);

        res.reset ();

        res.uri = uri;

        /* Protocol info */
        res.protocol = "http-get";
        res.mime_type = mime;
        res.dlna_profile = "MP3"; /* FIXME */

        res.width = width;
        res.height = height;

        this.didl_writer.add_res (res);

        /* FIXME: These lines should be remove once GB#526552 is fixed */
        res.uri = null;
        res.protocol = null;
        res.mime_type = null;
        res.dlna_profile = null;

        /* End of item */
        this.didl_writer.end_item ();
    }

    private void add_root_container () {
        add_container (this.root_id,
                       this.root_parent_id,
                       this.title,
                       this.get_root_children_count ());
    }

    private Tracker.Container? get_item_parent (string uri) {
        Tracker.Container container = null;
        string category;

        try {
            category = this.files.GetServiceType (uri);
        } catch (GLib.Error error) {
            critical ("failed to find service type for %s: %s",
                      uri,
                      error.message);

            return null;
        }

        foreach (Tracker.Container tmp in this.containers) {
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
}

[ModuleInit]
public MediaProvider register_media_provider (string        root_id,
                                              string        root_parent_id,
                                              GUPnP.Context context) {
    return new MediaTracker (root_id,
                             root_parent_id,
                             context);
}

