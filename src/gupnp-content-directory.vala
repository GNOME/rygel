/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
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
using GLib;
using GUPnP;

public class GUPnP.ContentDirectory: Service {
    uint32 system_update_id;

    MediaTracker tracker;

    construct {
        this.tracker = new MediaTracker ("0", this.context);
        
        /* FIXME: Use Vala's syntax for connecting signals when Vala adds
        * support for signal details. */
        Signal.connect (this,
                        "action-invoked::Browse",
                        (GLib.Callback) this.browse_cb,
                        null);
    }

    /* Browse action implementation */
    private void browse_cb (ServiceAction action) {
        string object_id, browse_flag;
        bool browse_metadata;
        string didl, sort_criteria, filter;
        uint starting_index, requested_count;
        uint num_returned, total_matches, update_id;

        /* Handle incoming arguments */
        action.get ("ObjectID", typeof (string), out object_id,
                    "BrowseFlag", typeof (string), out browse_flag,
                    "Filter", typeof (string), out filter,
                    "StartingIndex", typeof (uint), out starting_index,
                    "RequestedCount", typeof (uint), out requested_count,
                    "SortCriteria", typeof (string), out sort_criteria);

        /* BrowseFlag */
        if (browse_flag != null && browse_flag == "BrowseDirectChildren") {
            browse_metadata = false;
        } else if (browse_flag != null && browse_flag == "BrowseMetadata") {
            browse_metadata = true;
        } else {
            /*action.return_error (GUPnP.ControlError.INVALID_ARGS, null);*/
            action.return ();

            return;
        }

        /* ObjectID */
        if (object_id == null) {
            /* Stupid Xbox */
            action.get ("ContainerID", typeof (string), out object_id);
            if (object_id == null) {
                action.return_error (701, "No such object");

                return;
            }
        }

        if (browse_metadata) {
            didl = this.tracker.get_metadata (object_id,
                                                filter,
                                                sort_criteria,
                                                out update_id);

            num_returned = 1;
            total_matches = 1;
        } else {
            didl = this.tracker.browse (object_id,
                                        filter,
                                        starting_index,
                                        requested_count,
                                        sort_criteria,
                                        out num_returned,
                                        out total_matches,
                                        out update_id);
        }

        if (didl == null) {
            action.return_error (701, "No such object");

            return;
        }

        if (update_id == uint32.MAX)
            update_id = this.system_update_id;

        /* Set action return arguments */
        action.set ("Result", typeof (string), didl,
                    "NumberReturned", typeof (uint), num_returned,
                    "TotalMatches", typeof (uint), total_matches,
                    "UpdateID", typeof (uint), update_id);

        action.return ();
    }
}

