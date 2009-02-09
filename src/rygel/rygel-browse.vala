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

using Rygel;
using GUPnP;
using Gee;

/**
 * Browse action implementation. This class is more or less the state-machine
 * associated with the Browse action handling that exists to make asynchronous
 * handling of Browse action possible.
 */
public class Browse: GLib.Object {
    public const int MAX_REQUESTED_COUNT = 128;

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
    private MediaObject media_object;

    private MediaContainer root_container;
    private ServiceAction action;
    private Rygel.DIDLLiteWriter didl_writer;

    // Signals
    public signal void completed ();

    public Browse (ContentDirectory    content_dir,
                   owned ServiceAction action) {
        this.root_container = content_dir.root_container;
        this.action = (owned) action;

        this.didl_writer =
                new Rygel.DIDLLiteWriter (content_dir.http_server);
    }

    public void start () {
        /* Start DIDL-Lite fragment */
        this.didl_writer.start_didl_lite (null, null, true);

        /* Handle incoming arguments */
        this.parse_args ();

        this.fetch_media_object ();
    }

    private void got_media_object () {
        if (this.media_object == null) {
            this.handle_error (
                new ContentDirectoryError.NO_SUCH_OBJECT ("No such object"));
            return;
        }

        if (this.fetch_metadata) {
            // BrowseMetadata
            this.handle_metadata_request ();
        } else {
            // BrowseDirectChildren
            this.handle_children_request ();
        }
    }

    private void fetch_media_object () {
        if (this.object_id == this.root_container.id) {
            this.media_object = this.root_container;

            this.got_media_object ();
            return;
        }

        try {
            this.media_object =
                        this.root_container.find_object (this.object_id);
        } catch (Error err) {
            this.handle_error (err);
            return;
        }

        this.got_media_object ();
    }

    private void handle_metadata_request () {
        if (this.media_object is MediaContainer) {
            this.update_id = ((MediaContainer) this.media_object).update_id;
        } else {
            this.update_id = uint32.MAX;
        }

        try {
            this.didl_writer.serialize (this.media_object);
        } catch (Error err) {
            this.handle_error (err);
            return;
        }

        this.number_returned = 1;
        this.total_matches = 1;

        // Conclude the successful Browse action
        this.conclude ();
    }

    private void handle_children_request () {
        if (!(this.media_object is MediaContainer)) {
            this.handle_error (
                new ContentDirectoryError.NO_SUCH_OBJECT ("No such object"));
            return;
        }

        if (this.requested_count == 0)
            this.requested_count = MAX_REQUESTED_COUNT;

        var container = (MediaContainer) this.media_object;
        this.total_matches = container.child_count;
        if (this.requested_count == 0) {
            // No max count requested, try to fetch all children
            this.requested_count = this.total_matches;
        }

        if (!this.serialize_children ()) {
            return;
        }

        this.update_id = container.update_id;

        // Conclude the successful Browse action
        this.conclude ();
    }

    private void parse_args () {
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
            this.fetch_metadata = false;
            this.handle_error (
                    new ContentDirectoryError.INVALID_ARGS ("Invalid Args"));
        }

        /* ObjectID */
        if (this.object_id == null) {
            /* Stupid Xbox */
            this.action.get ("ContainerID",
                             typeof (string),
                             out this.object_id);
        }

        if (this.object_id == null) {
            // Sorry we can't do anything without ObjectID
            this.handle_error (
                new ContentDirectoryError.NO_SUCH_OBJECT ("No such object"));
        }
    }

    private void conclude () {
        /* End DIDL-Lite fragment */
        this.didl_writer.end_didl_lite ();

        /* Retrieve generated string */
        string didl = this.didl_writer.get_string ();

        if (this.update_id == uint32.MAX) {
            this.update_id = this.root_container.update_id;
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
            warning ("Failed to browse '%s': %s\n",
                     this.object_id,
                     error.message);
            this.action.return_error (error.code, error.message);
        } else {
            warning ("Failed to browse '%s': %s\n",
                     this.object_id,
                     error.message);
            this.action.return_error (701, error.message);
        }

        this.completed ();
    }

    private bool serialize_children () {
        var children = this.get_children ();
        if (children == null) {
            return false;
        }

        /* serialize all children */
        for (int i = 0; i < children.size; i++) {
            try {
                this.didl_writer.serialize (children[i]);
            } catch (Error err) {
                this.handle_error (err);
                return false;
            }
        }

        this.number_returned = children.size;

        return true;
    }

    private Gee.List<MediaObject>? get_children () {
        var container = (MediaContainer) this.media_object;

        try {
            var children = container.get_children (this.index,
                                                   this.requested_count);

            return children;
        } catch {
            this.handle_error (
                new ContentDirectoryError.NO_SUCH_OBJECT ("No such object"));
            return null;
        }
    }
}

