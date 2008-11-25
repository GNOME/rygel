/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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

using Rygel;
using GUPnP;
using DBus;

/**
 * Implementation of Tracker-based ContentDirectory service.
 */
public class Rygel.MediaTracker : ContentDirectory {
    public static const int MAX_REQUESTED_COUNT = 128;

    private MediaContainer root_container;

    /* FIXME: Make this a static if you know how to initize it */
    private List<TrackerContainer> containers;

    private SearchCriteriaParser search_parser;

    /* Pubic methods */
    public override void constructed () {
        // Chain-up to base first
        base.constructed ();

        this.root_container = new MediaContainer ("0",
                                                  "-1",
                                                  "MediaTracker",
                                                  this.containers.length ());

        this.containers = new List<TrackerContainer> ();
        this.containers.append
                        (new TrackerContainer ("16",
                                               this.root_container.id,
                                               "All Images",
                                               "Images",
                                               MediaItem.IMAGE_CLASS,
                                               context));
        this.containers.append
                        (new TrackerContainer ("14",
                                               this.root_container.id,
                                               "All Music",
                                               "Music",
                                               MediaItem.MUSIC_CLASS,
                                               context));
        this.containers.append
                        (new TrackerContainer ("15",
                                               this.root_container.id,
                                               "All Videos",
                                               "Videos",
                                               MediaItem.VIDEO_CLASS,
                                               context));

        this.search_parser = new SearchCriteriaParser ();

        weak string home_dir = Environment.get_home_dir ();

        /* Host the home dir of the user */
        this.context.host_path (home_dir, home_dir);
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
        if (container_id == this.root_container.id) {
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
                    container.add_children_from_db (didl_writer,
                                                    starting_index,
                                                    requested_count,
                                                    out total_matches);
            }
        }

        if (number_returned > 0) {
            update_id = uint32.MAX;
        } else {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }
    }

    public override void add_metadata
                            (DIDLLiteWriter didl_writer,
                             string         object_id,
                             string         filter,
                             string         sort_criteria,
                             out uint       update_id) throws GLib.Error {
        bool found = false;

        if (object_id == this.root_container.id) {
            this.root_container.serialize (didl_writer);

            found = true;
        } else {
            TrackerContainer container;

            /* First try containers */
            container = find_container_by_id (object_id);

            if (container != null) {
                container.serialize (didl_writer);

                found = true;
            } else {
                /* Now try items */
                container = get_item_parent (object_id);

                if (container != null)
                    found = container.add_item_from_db (didl_writer, object_id);
            }
        }

        if (!found) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        update_id = uint32.MAX;
    }

    /* Private methods */
    private uint add_root_container_children (DIDLLiteWriter didl_writer) {
        foreach (TrackerContainer container in this.containers)
            container.serialize (didl_writer);

        return this.containers.length ();
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

    private TrackerContainer? get_item_parent (string uri) {
        TrackerContainer container = null;
        string category;

        try {
            category = TrackerContainer.get_file_category (uri);
        } catch (GLib.Error error) {
            critical ("failed to find service type for %s: %s",
                      uri,
                      error.message);

            return null;
        }

        foreach (TrackerContainer tmp in this.containers) {
            if (tmp.category == category) {
                container = tmp;

                break;
            }
        }

        return container;
    }
}

