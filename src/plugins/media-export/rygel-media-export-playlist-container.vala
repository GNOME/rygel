/*
 * Copyright (C) 2013 Intel Corporation.
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

using Gee;
using GUPnP;

internal class Rygel.MediaExport.PlaylistContainer : DBContainer,
                                                     Rygel.WritableContainer {
    internal static const string URI = WritableContainer.WRITABLE_SCHEME +
                                       "playlist-container";
    public ArrayList<string> create_classes { get; set; }

    public PlaylistContainer (string id, string title) {
        Object (id : id,
                title : title,
                parent : null,
                child_count : 0);
    }

    public override void constructed () {
        base.constructed ();

        this.upnp_class = Rygel.MediaContainer.PLAYLIST;
        this.create_classes = new ArrayList<string> ();
        // Only items, no folders
        this.create_classes.add (Rygel.ImageItem.UPNP_CLASS);
        this.create_classes.add (Rygel.PhotoItem.UPNP_CLASS);
        this.create_classes.add (Rygel.VideoItem.UPNP_CLASS);
        this.create_classes.add (Rygel.AudioItem.UPNP_CLASS);
        this.create_classes.add (Rygel.MusicItem.UPNP_CLASS);

        // Need to add an URI otherwise core doesn't mark the container as
        // writable
        this.add_uri (PlaylistContainer.URI);
    }

    public override OCMFlags ocm_flags {
        get {
            var flags = base.ocm_flags;

            // This container does not allow upload
            flags &= ~(OCMFlags.UPLOAD | OCMFlags.UPLOAD_DESTROYABLE);
            flags &= ~(OCMFlags.CREATE_CONTAINER);

            return flags;
        }
    }

    public async void add_item (Rygel.MediaFileItem item,
                                Cancellable?    cancellable)
                                throws Error {
        throw new WritableContainerError.NOT_IMPLEMENTED
                                        (_("Can't create items in %s"),
                                         this.id);
    }

    public virtual async string add_reference (MediaObject  object,
                                               Cancellable? cancellable)
                                               throws Error {
        return MediaCache.get_default ().create_reference (object, this);
    }

    public async void remove_item (string id,
                                   Cancellable?    cancellable)
                                   throws Error {
        this.media_db.remove_by_id (id);
        this.updated ();
    }

    public async void add_container (Rygel.MediaContainer container,
                                     Cancellable?         cancellable)
                                     throws Error {
        throw new WritableContainerError.NOT_IMPLEMENTED
                                        (_("Can't add containers in %s"),
                                         this.id);
    }

    public async void remove_container (string id,
                                        Cancellable?    cancellable)
                                        throws Error {
        throw new WritableContainerError.NOT_IMPLEMENTED
                                        (_("Can't remove containers in %s"),
                                         this.id);
    }

}
