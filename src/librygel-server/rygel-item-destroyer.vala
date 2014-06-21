/*
 * Copyright (C) 2010 Nokia Corporation.
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

private errordomain Rygel.ItemDestroyerError {
    PARSE
}

/**
 * DestroyObject action implementation.
 */
internal class Rygel.ItemDestroyer: GLib.Object, Rygel.StateMachine {
    private string object_id;

    private ContentDirectory content_dir;
    private ServiceAction action;

    public Cancellable cancellable { get; set; }

    public ItemDestroyer (ContentDirectory    content_dir,
                          owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
    }

    public async void run () {
        try {
            this.action.get ("ObjectID", typeof (string), out this.object_id);
            if (this.object_id == null) {
                // Sorry we can't do anything without the ID
                throw new ContentDirectoryError.INVALID_ARGS
                                        (_("ContainerID missing"));
            }

            yield this.remove_object ();

            this.action.return ();

            debug (_("Successfully destroyed object '%s'"), this.object_id);
        } catch (Error error) {
            if (error is ContentDirectoryError) {
                this.action.return_error (error.code, error.message);
            } else {
                this.action.return_error (701, error.message);
            }

            warning (_("Failed to destroy object '%s': %s"),
                     this.object_id,
                     error.message);
        }

        this.completed ();
    }

    private async void remove_object () throws Error {
        var media_object = yield this.fetch_object ();
        var parent = media_object.parent as WritableContainer;

        if (media_object is MediaFileItem ) {
            yield parent.remove_item (this.object_id, this.cancellable);

            if (!(media_object as MediaFileItem).place_holder) {
                var writables = yield media_object.get_writables (this.cancellable);
                foreach (var file in writables) {
                    if (file.query_exists (this.cancellable)) {
                        file.delete (this.cancellable);
                    }
                }
            }
        } else {
            yield parent.remove_container (this.object_id, this.cancellable);
        }

        ObjectRemovalQueue.get_default ().dequeue (media_object);
    }

    private async MediaObject fetch_object () throws Error {
        var media_object = yield this.content_dir.root_container.find_object
                                        (this.object_id, this.cancellable);

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        } else if (!(OCMFlags.DESTROYABLE in media_object.ocm_flags)) {
            throw new ContentDirectoryError.RESTRICTED_OBJECT
                                        (_("Removal of object %s not allowed"),
                                         media_object.id);
        } else if (media_object.parent.restricted) {
            var msg = _("Object removal from %s not allowed");

            throw new ContentDirectoryError.RESTRICTED_PARENT (msg,
                                                               media_object.id);
        }

        return media_object;
    }
}
