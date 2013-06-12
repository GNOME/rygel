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
    private static Regex escape_regex;

    private string object_id;
    private string current_tag_value;
    private string new_tag_value;

    private ContentDirectory content_dir;
    private ServiceAction action;

    public Cancellable cancellable { get; set; }

    static construct {
        try {
            escape_regex = new Regex ("\\\\(.)");
        } catch (GLib.RegexError error) {
            assert_not_reached ();
        }
    }

    public ItemUpdater (ContentDirectory    content_dir,
                        owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
    }

    public async void run () {
        try {
            this.action.get ("ObjectID",
                                 typeof (string),
                                 out this.object_id,
                             "CurrentTagValue",
                                 typeof (string),
                                 out this.current_tag_value,
                             "NewTagValue",
                                 typeof (string),
                                 out this.new_tag_value);
            if (this.object_id == null) {
                // Sorry we can't do anything without the ID
                throw new ContentDirectoryError.INVALID_ARGS
                                        (_("Object id missing"));
            }

            yield this.update_object ();

            this.action.return ();

            debug (_("Successfully updated object '%s'"), this.object_id);
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

    private static string unescape (string value) {
        try {
            return ItemUpdater.escape_regex.replace (value, -1, 0, "\\1");
        } catch (GLib.RegexError error) {
            return value;
        }
    }

    private static LinkedList<string> csv_split (string? tag_values) {
        var list = new LinkedList<string> ();

        if (tag_values == null) {
            return list;
        }

        var escape = false;
        var token_start = 0;
        var token_length = 0;
        var len = tag_values.length;

        for (int iter = 0; iter < len; ++iter) {
            var c = tag_values[iter];
            var increase = true;

            if (escape) {
                escape = false;
            } else {
                switch (c) {
                case '\\':
                    escape = true;

                    break;
                case ',':
                    var value = tag_values.substring (token_start,
                                                      token_length);

                    list.add (ItemUpdater.unescape (value));
                    token_start += token_length + 1;
                    token_length = 0;
                    increase = false;

                    break;
                }
            }
            if (increase) {
                ++token_length;
            }
        }

        list.add (ItemUpdater.unescape (tag_values.substring (token_start)));

        return list;
    }

    private async void update_object () throws Error {
        var media_object = yield this.fetch_object ();
        var current_list = csv_split (this.current_tag_value);
        var new_list = csv_split (this.new_tag_value);
        var result = yield media_object.apply_fragments
                                        (current_list,
                                         new_list,
                                         this.content_dir.http_server);

        switch (result) {
        case DIDLLiteFragmentResult.OK:
            break;
        case DIDLLiteFragmentResult.CURRENT_BAD_XML:
        case DIDLLiteFragmentResult.CURRENT_INVALID:
            throw new ContentDirectoryError.INVALID_CURRENT_TAG_VALUE
                                        (_("Bad current tag value."));
        case DIDLLiteFragmentResult.NEW_BAD_XML:
        case DIDLLiteFragmentResult.NEW_INVALID:
            throw new ContentDirectoryError.INVALID_NEW_TAG_VALUE
                                        (_("Bad new tag value."));
        case DIDLLiteFragmentResult.REQUIRED_TAG:
            throw new ContentDirectoryError.REQUIRED_TAG
                                        (_("Tried to delete required tag."));
        case DIDLLiteFragmentResult.READONLY_TAG:
            throw new ContentDirectoryError.READ_ONLY_TAG
                                        (_("Tried to change read-only property."));
        case DIDLLiteFragmentResult.MISMATCH:
            throw new ContentDirectoryError.PARAMETER_MISMATCH
                                        (_("Parameter count mismatch."));
        default:
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("Unknown error."));
        }
    }

    private async MediaObject fetch_object () throws Error {
        var media_object = yield this.content_dir.root_container.find_object
                                        (this.object_id,
                                         this.cancellable);

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        } else if (!(OCMFlags.CHANGE_METADATA in media_object.ocm_flags)) {
            var msg = _("Metadata modification of object %s not allowed");

            throw new ContentDirectoryError.RESTRICTED_OBJECT (msg,
                                                               media_object.id);
        } else if (media_object.parent.restricted) {
            var msg = _("Metadata modification of object %s being a child of restricted object %s not allowed");

            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (msg,
                                         media_object.id,
                                         media_object.parent.id);
        }

        return media_object;
    }
}
