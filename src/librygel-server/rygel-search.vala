/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;
using Gee;
using Soup;

/**
 * Search action implementation.
 */
internal class Rygel.Search:  Rygel.MediaQueryAction {
    // In arguments
    public string search_criteria;

    public Search (ContentDirectory    content_dir,
                   owned ServiceAction action) {
        base (content_dir, action);

        this.object_id_arg = "ContainerID";
    }

    protected override void parse_args () throws Error {
        base.parse_args ();

        this.action.get ("SearchCriteria",
                            typeof (string),
                            out this.search_criteria);

        if (this.search_criteria == null) {
            throw new ContentDirectoryError.INVALID_ARGS
                                        ("No search criteria given");
        }

        debug ("Executing search request: %s", this.search_criteria);
    }

    protected override async MediaObjects fetch_results
                                        (MediaObject media_object)
                                         throws Error {
        if (!(media_object is SearchableContainer)) {
            return new MediaObjects ();
        }

        var container = media_object as SearchableContainer;
        var parser = new Rygel.SearchCriteriaParser (this.search_criteria);
        yield parser.run ();

        if (parser.err != null) {
            throw new ContentDirectoryError.INVALID_SEARCH_CRITERIA
                                        (_("Invalid search criteria given"));
        }

        var sort_criteria = this.sort_criteria ?? container.sort_criteria;

        if (this.hacks != null) {
            return yield this.hacks.search (container,
                                            parser.expression,
                                            this.index,
                                            this.requested_count,
                                            sort_criteria,
                                            this.cancellable,
                                            out this.total_matches);
        } else {
            return yield container.search (parser.expression,
                                           this.index,
                                           this.requested_count,
                                           sort_criteria,
                                           this.cancellable,
                                           out this.total_matches);
        }
    }

    protected override void handle_error (Error error) {
        warning (_("Failed to search in “%s”: %s"),
                 this.object_id,
                 error.message);

        base.handle_error (error);
    }
}
