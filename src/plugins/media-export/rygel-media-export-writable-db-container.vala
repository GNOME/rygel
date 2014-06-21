/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

/**
 * A DB container that is both Trackable and Writable.
 *
 * Clients can upload items to this container, causing
 * the items to be saved to the filesystem to be
 * served again subsequently.
 */
internal class Rygel.MediaExport.WritableDbContainer : TrackableDbContainer,
                                                       Rygel.WritableContainer {
    public ArrayList<string> create_classes { get; set; }

    public WritableDbContainer (string id, string title) {
        Object (id : id,
                title : title,
                parent : null,
                child_count : 0);
    }

    public override void constructed () {
        base.constructed ();

        this.create_classes = new ArrayList<string> ();

        // Items
        this.create_classes.add (Rygel.ImageItem.UPNP_CLASS);
        this.create_classes.add (Rygel.PhotoItem.UPNP_CLASS);
        this.create_classes.add (Rygel.VideoItem.UPNP_CLASS);
        this.create_classes.add (Rygel.AudioItem.UPNP_CLASS);
        this.create_classes.add (Rygel.MusicItem.UPNP_CLASS);
        this.create_classes.add (Rygel.PlaylistItem.UPNP_CLASS);

        // Containers
        this.create_classes.add (Rygel.MediaContainer.UPNP_CLASS);
    }

    public virtual async void add_item (Rygel.MediaFileItem item,
                                        Cancellable? cancellable)
                                        throws Error {
        item.parent = this;
        var file = File.new_for_uri (item.get_primary_uri ());
        // TODO: Mark as place-holder. Make this proper some time.
        if (file.is_native ()) {
            item.modified = int64.MAX;
        }
        item.id = MediaCache.get_id (file);
        yield this.add_child_tracked (item);
        this.media_db.make_object_guarded (item);
    }

    public virtual async string add_reference (MediaObject  object,
                                               Cancellable? cancellable)
                                               throws Error {
        return MediaCache.get_default ().create_reference (object, this);
    }

    public virtual async void add_container (MediaContainer container,
                                             Cancellable?   cancellable)
                                             throws Error {
        container.parent = this;
        switch (container.upnp_class) {
        case MediaContainer.STORAGE_FOLDER:
        case MediaContainer.UPNP_CLASS:
            var file = File.new_for_uri (container.get_primary_uri ());
            container.id = MediaCache.get_id (file);
            if (file.is_native ()) {
                file.make_directory_with_parents (cancellable);
            }
            break;
        default:
            throw new WritableContainerError.NOT_IMPLEMENTED
                                        ("upnp:class %s not supported",
                                         container.upnp_class);
        }

        yield this.add_child_tracked (container);
        this.media_db.make_object_guarded (container);
    }

    protected override async void remove_child (MediaObject object) {
        yield base.remove_child (object);
        var file = File.new_for_uri (object.get_primary_uri ());
        try {
            yield file.delete_async ();
        } catch (Error error) {
            warning (_("Failed to remove file %s: %s"),
                     file.get_path (),
                     error.message);
        }
    }

    public virtual async void remove_item (string id, Cancellable? cancellable)
                                           throws Error {
        var object = this.media_db.get_object (id);
        if (object != null) {
            yield this.remove_child_tracked (object);
        } else {
            warning (_("Could not find object %d in cache"), id);
        }
    }

    public virtual async void remove_container (string id,
                                                Cancellable? cancellable)
                                                throws Error {
        yield this.remove_item (id, cancellable);
    }

    public void remove_tracked (MediaObject object) throws Error {
        this.updated (object, ObjectEventType.DELETED);
        this.total_deleted_child_count++;

        this.media_db.remove_by_id (object.id);

        this.updated ();
        this.child_removed (object);
    }

}
