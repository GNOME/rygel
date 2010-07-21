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
internal class Rygel.Browse: Rygel.MediaQueryAction {
    // The media object corresponding to object_id
    private bool fetch_metadata;

    public Browse (ContentDirectory    content_dir,
                   owned ServiceAction action) {
        base (content_dir,
              action,
              "ObjectID",
              _("Failed to browse '%s': %s\n"));
    }

    protected override void parse_args () throws Error {
        base.parse_args ();

        this.action.get ("BrowseFlag", typeof (string), out this.browse_flag);

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
    }

    protected override async Gee.List<MediaObject> fetch_results (
                                        MediaObject media_object) throws Error {
        if (this.fetch_metadata) {
            // BrowseMetadata
            return this.handle_metadata_request (media_object);
        } else {
            // BrowseDirectChildren
            return yield this.handle_children_request (media_object);
        }
    }

    private Gee.List<MediaObject> handle_metadata_request (
                                        MediaObject media_object)
                                        throws Error {
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
        debug ("Fetched %u children of container '%s' from index %u.",
               this.requested_count,
               this.object_id,
               this.index);

        return children;
    }
}

