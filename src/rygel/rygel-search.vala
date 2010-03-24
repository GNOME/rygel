/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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
 * Search action implementation.
 */
internal class Rygel.Search: GLib.Object, Rygel.StateMachine {
    // In arguments
    public string container_id;
    public string search_criteria;
    public string filter;
    public uint   index;           // Starting index
    public uint   requested_count;
    public string sort_criteria;

    // Out arguments
    public uint number_returned;
    public uint total_matches;
    public uint update_id;

    private MediaContainer root_container;
    private uint32 system_update_id;
    private ServiceAction action;
    private Rygel.DIDLLiteWriter didl_writer;
    private XBoxHacks xbox_hacks;

    public Cancellable cancellable { get; set; }

    public Search (ContentDirectory    content_dir,
                   owned ServiceAction action) {
        this.root_container = content_dir.root_container;
        this.system_update_id = content_dir.system_update_id;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;

        this.didl_writer =
                new Rygel.DIDLLiteWriter (content_dir.http_server);

        try {
            this.xbox_hacks = new XBoxHacks (action.get_message ());
        } catch { /* This just means we are not dealing with Xbox, yay! */ }
    }

    public async void run () {
        // Start by parsing the 'in' arguments
        this.action.get ("ContainerID",
                            typeof (string),
                            out this.container_id,
                         "SearchCriteria",
                            typeof (string),
                            out this.search_criteria,
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

        try {
            if (this.container_id == null || this.search_criteria == null) {
                // Sorry we can't do anything without these two parameters
                throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                        "No such container");
            }

            debug ("Executing search request: %s", this.search_criteria);

            if (this.xbox_hacks != null) {
                this.xbox_hacks.translate_container_id (ref this.container_id);
            }

            var container = yield this.fetch_container ();
            var results = yield this.fetch_results (container);

            // Serialize results
            foreach (var result in results) {
                if (result is MediaItem && this.xbox_hacks != null) {
                    this.xbox_hacks.apply (result as MediaItem);
                }

                this.didl_writer.serialize (result);
            }

            this.conclude ();
        } catch (Error err) {
            this.handle_error (err);
        }
    }

    private async MediaContainer fetch_container () throws Error {
        if (this.container_id == this.root_container.id) {
            return this.root_container;
        }

        var media_object = yield this.root_container.find_object (
                                        this.container_id,
                                        this.cancellable);
        if (media_object == null || !(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT (
                    "Specified container does not exist.");
        }

        return media_object as MediaContainer;
    }

    private async Gee.List<MediaObject> fetch_results (
                                        MediaContainer container)
                                        throws Error {
        this.update_id = container.update_id;

        var parser = new Rygel.SearchCriteriaParser (this.search_criteria);
        yield parser.run ();

        if (parser.err != null) {
            throw parser.err;
        }

        var results = yield container.search (parser.expression,
                                              this.index,
                                              this.requested_count,
                                              out this.total_matches,
                                              this.cancellable);
        if (results.size == 0) {
            throw new ContentDirectoryError.CANT_PROCESS (
                                        "No objects found that could satisfy" +
                                        " the given search criteria.");
        }

        this.number_returned = results.size;

        return results;
    }

    private void conclude () {
        // Apply the filter from the client
        this.didl_writer.filter (this.filter);

        // Retrieve generated string
        string didl = this.didl_writer.get_string ();

        if (this.update_id == uint32.MAX) {
            this.update_id = this.system_update_id;
        }

        // Set action return arguments
        this.action.set ("Result", typeof (string), didl,
                         "NumberReturned", typeof (uint), this.number_returned,
                         "TotalMatches", typeof (uint), this.total_matches,
                         "UpdateID", typeof (uint), this.update_id);

        this.action.return ();
        this.completed ();
    }

    private void handle_error (Error error) {
        warning ("Failed to search in '%s': %s\n",
                 this.container_id,
                 error.message);

        if (error is ContentDirectoryError) {
            this.action.return_error (error.code, error.message);
        } else {
            this.action.return_error (701, error.message);
        }

        this.completed ();
    }
}

