/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

internal class Rygel.ReferenceCreator : GLib.Object, Rygel.StateMachine {
    private ContentDirectory content_directory;
    private ServiceAction action;

    // Props
    public Cancellable cancellable { get; set; }
    public string container_id;

    // Local props
    public string object_id;

    public ReferenceCreator (ContentDirectory    content_dir,
                             owned ServiceAction action) {
        this.content_directory = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
    }

    public void parse_arguments () throws Error {
        this.action.get ("ContainerID",
                            typeof (string), out this.container_id,
                         "ObjectID",
                             typeof (string), out this.object_id);
        if (this.container_id == null) {
            throw new ContentDirectoryError.INVALID_ARGS
                                        (_("“ContainerID” agument missing."));
        }

        if (this.object_id == null) {
            throw new ContentDirectoryError.INVALID_ARGS
                                        (_("“ObjectID” argument missing."));
        }
    }

    public async void run () {
        try {
            this.parse_arguments ();
            var root_container = this.content_directory.root_container;

            var object = yield root_container.find_object
                                        (this.object_id, this.cancellable);
            if (object == null) {
                throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
            }

            var container = yield this.fetch_container ();

            var new_id = yield container.add_reference (object,
                                                        this.cancellable);

            this.action.set ("NewID", typeof (string), new_id);
            this.action.return_success ();
            this.completed ();
        } catch (Error error) {
            if (error is ContentDirectoryError) {
                this.action.return_error (error.code, error.message);
            } else {
                this.action.return_error (402, error.message);
            }

            warning (_("Failed to create object under “%s”: %s"),
                     this.container_id,
                     error.message);

            this.completed ();

            return;
        }
    }

    /**
     * Get the container to create the item in.
     *
     * This will either try to fetch the container supplied by the caller or
     * search for a container if the caller supplied the "DLNA.ORG_AnyContainer"
     * id.
     *
     * @return an instance of WritableContainer matching the criteria
     * @throws ContentDirectoryError for various problems
     */
    private async WritableContainer fetch_container () throws Error {
        MediaObject media_object = null;

        var root_container = this.content_directory.root_container;
        media_object = yield root_container.find_object (this.container_id,
                                                         this.cancellable);

        if (media_object == null || !(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_CONTAINER
                                        (_("No such object"));
        } else if (!(media_object is WritableContainer)) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                         media_object.id);
        }

        // FIXME: Check for @restricted=1 missing?

        return media_object as WritableContainer;
    }


}
