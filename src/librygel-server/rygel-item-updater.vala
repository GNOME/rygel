/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Krzesimir Nowak <krnowak@openismus.com>
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
 * UpdateObject action implementation.
 */
internal class Rygel.ItemUpdater: GLib.Object, Rygel.StateMachine {
    private string object_id;
    private string current_tag_value;
    private string new_tag_value;

    private ContentDirectory content_dir;
    private ServiceAction action;

    public Cancellable cancellable { get; set; }

    public ItemUpdater (ContentDirectory    content_dir,
                        owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
    }

    public async void run () {
        try {
            this.action.get ("ObjectID", typeof (string), out this.object_id);
            this.action.get ("CurrentTagValue",
                             typeof (string),
                             out this.current_tag_value);
            this.action.get ("NewTagValue",
                             typeof (string),
                             out this.new_tag_value);
            if (this.object_id == null) {
                // Sorry we can't do anything without the ID
                throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
            }
            // I have no idea what to throw here.
            // For now I just treat it as empty strings.
            if (this.current_tag_value == null) {
                this.current_tag_value = "";
            }
            if (this.new_tag_value == null) {
                this.new_tag_value = "";
            }

            yield this.update_object ();

            this.action.return ();

            debug (_("Successfully destroyed object '%s'"), this.object_id);
        } catch (Error error) {
            if (error is ContentDirectoryError) {
                this.action.return_error (error.code, error.message);
            } else {
                this.action.return_error (701, error.message);
            }

            warning (_("Failed to update object '%s': %s"),
                     this.object_id,
                     error.message);
        }

        this.completed ();
    }

    private static LinkedList<string> csv_split (string tag_values) {
        var list = new LinkedList<string> ();
        /*
        var escape = false;
        var token_start = 0;
        var token_length = 0;
        */

        /* TODO: Find out how to iterate over chars in string.
        foreach (var c in tag_values) {
            if (escape) {
                escape = false;
            } else {
                switch (c) {
                case '\\':
                    escape = true;
                    break;

                case ',':
                    list.add (tag_values.substring (token_start, token_length));
                    token_start += token_length + 1;
                    token_length = 0;
                    break;
                }
            }
            ++token_length;
        }
        */

        return list;
    }

    private async void update_object () throws Error {
        var media_object = yield this.fetch_object ();
        var current_list = csv_split (this.current_tag_value);
        var new_list = csv_split (this.new_tag_value);

        if (current_list.size != new_list.size) {
            throw new ContentDirectoryError.PARAMETER_MISMATCH
                (_("CurrentTagValue should have the same number of elements as " +
                   "NewTagValue (%s vs %s)."),
                 current_list.size,
                 new_list.size);
        }
        /* Just to avoid some unused warning. */
        if (media_object == null) {
            return;
        }
    }

    private async MediaObject fetch_object () throws Error {
        var media_object = yield this.content_dir.root_container.find_object
                                        (this.object_id, this.cancellable);

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        } else if (!(OCMFlags.CHANGE_METADATA in media_object.ocm_flags)) {
            var msg = _("Metadata modification of object %s not allowed");

            throw new ContentDirectoryError.RESTRICTED_OBJECT (msg,
                                                               media_object.id);
        } else if (media_object.parent.restricted) {
            var msg = _("Metadata modification of object %s being a child " +
                        "of restricted object %s not allowed");

            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (msg,
                                         media_object.id,
                                         media_object.parent.id);
        }

        return media_object;
    }
}
