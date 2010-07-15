/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
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
using Gee;
using Soup;

/**
 * Browse action implementation. This class is more or less the state-machine
 * associated with the Browse action handling that exists to make asynchronous
 * handling of Browse action possible.
 */
internal class Rygel.Browse: GLib.Object, Rygel.StateMachine {
    // In arguments
    public string object_id;
    public string browse_flag;
    public string filter;
    public uint   index;           // Starting index
    public uint   requested_count;
    public string sort_criteria;

    // Out arguments
    public uint number_returned;
    public uint total_matches;
    public uint update_id;

    // The media object corresponding to object_id
    private bool fetch_metadata;

    private MediaContainer root_container;
    private uint32 system_update_id;
    private ServiceAction action;
    private Rygel.DIDLLiteWriter didl_writer;
    private XBoxHacks xbox_hacks;

    public Cancellable cancellable { get; set; }

    public Browse (ContentDirectory    content_dir,
                   owned ServiceAction action) {
        this.root_container = content_dir.root_container;
        this.system_update_id = content_dir.system_update_id;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;

        this.didl_writer = new Rygel.DIDLLiteWriter (content_dir.http_server);

        try {
            this.xbox_hacks = new XBoxHacks.for_action (this.action);
        } catch { /* This just means we are not dealing with Xbox, yay! */ }
    }

    public async void run () {
        try {
            this.parse_args ();

            var media_object = yield this.fetch_media_object ();

            Gee.List<MediaObject> results;
            if (this.fetch_metadata) {
                // BrowseMetadata
                results = this.handle_metadata_request (media_object);
            } else {
                // BrowseDirectChildren
                results = yield this.handle_children_request (media_object);
            }

            foreach (var result in results) {
                if (result is MediaItem && this.xbox_hacks != null) {
                    this.xbox_hacks.apply (result as MediaItem);
                }

                this.didl_writer.serialize (result);
            }

            // Conclude the successful Browse action
            this.conclude ();
        } catch (Error err) {
            this.handle_error (err);
        }
    }

    private async void parse_args () throws Error {
        /* Start by parsing the 'in' arguments */
        this.action.get ("ObjectID", typeof (string), out this.object_id,
                    "BrowseFlag", typeof (string), out this.browse_flag,
                    "Filter", typeof (string), out this.filter,
                    "StartingIndex", typeof (uint), out this.index,
                    "RequestedCount", typeof (uint), out this.requested_count,
                    "SortCriteria", typeof (string), out this.sort_criteria);

        /* BrowseFlag */
        if (this.browse_flag != null &&
            this.browse_flag == "BrowseDirectChildren") {
            this.fetch_metadata = false;
        } else if (this.browse_flag != null &&
                   this.browse_flag == "BrowseMetadata") {
            this.fetch_metadata = true;
        } else {
            throw new ContentDirectoryError.INVALID_ARGS (
                                        _("Invalid Arguments"));
        }

        /* ObjectID */
        if (this.object_id == null) {
            /* Stupid Xbox */
            this.action.get ("ContainerID",
                             typeof (string),
                             out this.object_id);
            // Map some special browse requests to browse on the root folder
            if (this.object_id == "15" ||
                this.object_id == "14" ||
                this.object_id == "16") {
                this.object_id = "0";
            }
        }

        if (this.object_id == null) {
            // Sorry we can't do anything without ObjectID
            throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                        _("No such object"));
        }
    }

    private async MediaObject fetch_media_object () throws Error {
        if (this.object_id == this.root_container.id) {
            return this.root_container;
        } else {
            debug ("searching for object '%s'..", this.object_id);
            var media_object = yield this.root_container.find_object (
                                        this.object_id,
                                        this.cancellable);
            if (media_object == null) {
                throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                        _("No such object"));
            }
            debug ("object '%s' found.", this.object_id);

            return media_object;
        }
    }

    private Gee.List<MediaObject> handle_metadata_request (
                                        MediaObject media_object)
                                        throws Error {
        if (media_object is MediaContainer) {
            this.update_id = ((MediaContainer) media_object).update_id;
        } else {
            this.update_id = uint32.MAX;
        }

        this.number_returned = 1;
        this.total_matches = 1;

        var results = new ArrayList<MediaObject> ();
        results.add (media_object);

        return results;
    }

    private async Gee.List<MediaObject> handle_children_request (
                                        MediaObject media_object)
                                        throws Error {
        if (!(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                        _("No such object"));
        }

        var container = (MediaContainer) media_object;
        this.total_matches = container.child_count;
        this.update_id = container.update_id;

        if (this.requested_count == 0) {
            // No max count requested, try to fetch all children
            this.requested_count = this.total_matches;
        }

        debug ("Fetching %u children of container '%s' from index %u..",
               this.requested_count,
               this.object_id,
               this.index);
        var children = yield container.get_children (this.index,
                                                     this.requested_count,
                                                     this.cancellable);
        this.number_returned = children.size;
        debug ("Fetched %u children of container '%s' from index %u.",
               this.requested_count,
               this.object_id,
               this.index);

        return children;
    }

    private void conclude () {
        // Apply the filter from the client
        this.didl_writer.filter (this.filter);

        /* Retrieve generated string */
        string didl = this.didl_writer.get_string ();

        if (this.update_id == uint32.MAX) {
            this.update_id = this.system_update_id;
        }

        /* Set action return arguments */
        this.action.set ("Result", typeof (string), didl,
                         "NumberReturned", typeof (uint), this.number_returned,
                         "TotalMatches", typeof (uint), this.total_matches,
                         "UpdateID", typeof (uint), this.update_id);

        this.action.return ();
        this.completed ();
    }

    private void handle_error (Error error) {
        if (error is ContentDirectoryError) {
            warning (_("Failed to browse '%s': %s\n"),
                     this.object_id,
                     error.message);
            this.action.return_error (error.code, error.message);
        } else {
            warning (_("Failed to browse '%s': %s\n"),
                     this.object_id,
                     error.message);
            this.action.return_error (701, error.message);
        }

        this.completed ();
    }
}

