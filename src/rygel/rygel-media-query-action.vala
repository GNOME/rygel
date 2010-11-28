/*
 * Copyright (C) 2010 Nokia Corporation.
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
using Gee;

/**
 * Base class of Browse and Search actions.
 */
internal abstract class Rygel.MediaQueryAction : GLib.Object, StateMachine {
    private const string DEFAULT_SORT_CRITERIA = "-dc:title";

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

    public Cancellable cancellable { get; set; }

    protected MediaContainer root_container;
    protected HTTPServer http_server;
    protected uint32 system_update_id;
    protected ServiceAction action;
    protected DIDLLiteWriter didl_writer;
    protected XBoxHacks xbox_hacks;
    protected string object_id_arg;

    protected MediaQueryAction (ContentDirectory    content_dir,
                                owned ServiceAction action) {
        this.root_container = content_dir.root_container;
        this.http_server = content_dir.http_server;
        this.system_update_id = content_dir.system_update_id;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;

        this.didl_writer = new DIDLLiteWriter (null);

        try {
            this.xbox_hacks = new XBoxHacks.for_action (this.action);
        } catch { /* This just means we are not dealing with Xbox, yay! */ }
    }

    public async void run () {
        try {
            this.parse_args ();

            var media_object = yield this.fetch_media_object ();
            var results = yield this.fetch_results (media_object);

            this.number_returned = results.size;
            if (media_object is MediaContainer) {
                this.update_id = ((MediaContainer) media_object).update_id;
            } else {
                this.update_id = uint32.MAX;
            }

            results.sort_by_criteria (this.sort_criteria);

            results.serialize (this.didl_writer,
                               this.http_server,
                               this.xbox_hacks);

            // Conclude the successful Browse/Search action
            this.conclude ();
        } catch (Error err) {
            this.handle_error (err);
        }
    }

    protected virtual void parse_args () throws Error {
        this.action.get (this.object_id_arg,
                             typeof (string),
                             out this.object_id,
                         "Filter",
                             typeof (string),
                             out this.filter,
                         "StartingIndex",
                             typeof (uint),
                             out this.index,
                         "RequestedCount",
                             typeof (uint),
                             out this.requested_count,
                         "SortCriteria",
                             typeof (string),
                             out this.sort_criteria);

        if (this.object_id == null) {
            // Sorry we can't do anything without ObjectID
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        }

        if (this.sort_criteria == null) {
            this.sort_criteria = DEFAULT_SORT_CRITERIA;
        }

        if (this.xbox_hacks != null) {
            this.xbox_hacks.translate_container_id (this, ref this.object_id);
        }
    }

    protected abstract async MediaObjects fetch_results
                                        (MediaObject media_object) throws Error;

    private async MediaObject fetch_media_object () throws Error {
        if (this.object_id == this.root_container.id) {
            return this.root_container;
        } else {
            debug ("searching for object '%s'..", this.object_id);
            var media_object = yield this.root_container.find_object
                                        (this.object_id, this.cancellable);
            if (media_object == null) {
                throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
            }
            debug ("object '%s' found.", this.object_id);

            return media_object;
        }
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
        this.action.set ("Result",
                             typeof (string),
                             didl,
                         "NumberReturned",
                             typeof (uint),
                             this.number_returned,
                         "TotalMatches",
                             typeof (uint),
                             this.total_matches,
                         "UpdateID",
                             typeof (uint),
                             this.update_id);

        this.action.return ();
        this.completed ();
    }

    protected virtual void handle_error (Error error) {
        if (error is ContentDirectoryError) {
            this.action.return_error (error.code, error.message);
        } else {
            this.action.return_error (701, error.message);
        }

        this.completed ();
    }
}
