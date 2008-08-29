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

using GUPnP;

public class GUPnP.ContentDirectory: Service {
    string feature_list;

    MediaManager media_manager;

    construct {
        this.media_manager = new MediaManager (this.context);

        this.feature_list =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Features xmlns=\"urn:schemas-upnp-org:av:avs\" " +
            "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
            "xsi:schemaLocation=\"urn:schemas-upnp-org:av:avs" +
            "http://www.upnp.org/schemas/av/avs-v1-20060531.xsd\">" +
            "</Features>";

        this.action_invoked["Browse"] += this.browse_cb;

        /* Connect SystemUpdateID related signals */
        this.action_invoked["GetSystemUpdateID"] +=
                                                this.get_system_update_id_cb;
        this.query_variable["SystemUpdateID"] += this.query_system_update_id;

        /* Connect SearchCapabilities related signals */
        this.action_invoked["GetSearchCapabilities"] +=
                                                this.get_search_capabilities_cb;
        this.query_variable["SearchCapabilities"] +=
                                                this.query_search_capabilities;

        /* Connect SortCapabilities related signals */
        this.action_invoked["GetSortCapabilities"] +=
                                                this.get_sort_capabilities_cb;
        this.query_variable["SortCapabilities"] +=
                                                this.query_sort_capabilities;

        /* Connect FeatureList related signals */
        this.action_invoked["GetFeatureList"] += this.get_feature_list_cb;
        this.query_variable["FeatureList"] += this.query_feature_list;
    }

    /* Browse action implementation */
    private void browse_cb (ContentDirectory content_dir,
                            ServiceAction    action) {
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
            action.return_error (402, "Invalid Args");

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

        try {
            if (browse_metadata) {
                didl = this.media_manager.get_metadata (object_id,
                                                        filter,
                                                        sort_criteria,
                                                        out update_id);

                num_returned = 1;
                total_matches = 1;
            } else {
                didl = this.media_manager.browse (object_id,
                                                  filter,
                                                  starting_index,
                                                  requested_count,
                                                  sort_criteria,
                                                  out num_returned,
                                                  out total_matches,
                                                  out update_id);
            }
        } catch (Error error) {
            action.return_error (701, "No such object");

            return;
        }

        /* Set action return arguments */
        action.set ("Result", typeof (string), didl,
                    "NumberReturned", typeof (uint), num_returned,
                    "TotalMatches", typeof (uint), total_matches,
                    "UpdateID", typeof (uint), update_id);

        action.return ();
    }

    /* GetSystemUpdateID action implementation */
    private void get_system_update_id_cb (ContentDirectory content_dir,
                                          ServiceAction    action) {
        /* Set action return arguments */
        action.set ("Id", typeof (uint32), this.media_manager.system_update_id);

        action.return ();
    }

    /* Query GetSystemUpdateID */
    private void query_system_update_id (ContentDirectory content_dir,
                                         string variable,
                                         ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (uint32));
        value.set_uint (this.media_manager.system_update_id);
    }

    /* action GetSearchCapabilities implementation */
    private void get_search_capabilities_cb (ContentDirectory content_dir,
                                             ServiceAction    action) {
        /* Set action return arguments */
        action.set ("SearchCaps", typeof (string), "");

        action.return ();
    }

    /* Query SearchCapabilities */
    private void query_search_capabilities (ContentDirectory content_dir,
                                            string variable,
                                            ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string ("");
    }

    /* action GetSortCapabilities implementation */
    private void get_sort_capabilities_cb (ContentDirectory content_dir,
                                           ServiceAction    action) {
        /* Set action return arguments */
        action.set ("SortCaps", typeof (string), "");

        action.return ();
    }

    /* Query SortCapabilities */
    private void query_sort_capabilities (ContentDirectory content_dir,
                                          string variable,
                                          ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string ("");
    }

    /* action GetFeatureList implementation */
    private void get_feature_list_cb (ContentDirectory content_dir,
                                      ServiceAction    action) {
        /* Set action return arguments */
        action.set ("FeatureList", typeof (string), this.feature_list);

        action.return ();
    }

    /* Query FeatureList */
    private void query_feature_list (ContentDirectory content_dir,
                                     string variable,
                                     ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (this.feature_list);
    }
}

