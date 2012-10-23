/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
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

public enum Rygel.ObjectEventType {
    ADDED = 0,
    MODIFIED = 1,
    DELETED = 2
}

/**
 * This is a container (folder) for media items and child containers.
 *
 * It provides a basic serialization implementation (to DIDLLiteWriter).
 *
 * A derived class should provide a working implementation of get_children
 * and should emit the container_updated signal.
 */
public abstract class Rygel.MediaContainer : MediaObject {
    public const string UPNP_CLASS = "object.container";
    public const string STORAGE_FOLDER = UPNP_CLASS + ".storageFolder";
    public const string MUSIC_ALBUM = UPNP_CLASS + ".album.musicAlbum";
    public const string MUSIC_ARTIST = UPNP_CLASS + ".person.musicArtist";
    public const string MUSIC_GENRE = UPNP_CLASS + ".genre.musicGenre";

    private const string DEFAULT_SORT_CRITERIA = "+upnp:class,+dc:title";
    public const string ALBUM_SORT_CRITERIA = "+upnp:class," +
                                              "+rygel:originalVolumeNumber," +
                                              "+upnp:originalTrackNumber," +
                                              "+dc:title";

    /* TODO: When we implement ContentDirectory v4, this will be emitted also
     * when child _items_ are updated.
     */

    /**
     * The container_updated signal is emitted if a child container under the
     * tree of this container has been updated. object is set to
     * the MediaObject being the source of container update. Note that
     * it may be even set to container itself.
     *
     * @param container The child container that has been updated.
     * @param object the object that got changed.
     * @param event_type describes what actually happened to object.
     * @param sub_tree_update whether the modification is part of
     * sub-tree update.
     */
    public signal void container_updated (MediaContainer container,
                                          MediaObject object,
                                          ObjectEventType event_type,
                                          bool sub_tree_update);

    /**
     * sub_tree_updates_finished signal is emitted when all of
     * sub-tree operations are finished.
     *
     * @param sub_tree_root - root of a sub-tree where all operations
     * were performed.
     */
    public signal void sub_tree_updates_finished (MediaObject sub_tree_root);

    public int child_count;
    public uint32 update_id;
    public int64 storage_used;

    // This is a uint32 in UPnP. SystemUpdateID should reach uint32.MAX way
    // before this variable and cause a SystemResetProcedure.
    public int64 total_deleted_child_count;

    public string sort_criteria { set; get; default = DEFAULT_SORT_CRITERIA; }

    internal override OCMFlags ocm_flags {
        get {
            if (!(this is WritableContainer) || this.uris.size == 0) {
                return OCMFlags.NONE;
            }

            var flags = OCMFlags.NONE;

            var allow_upload = true;
            var config = MetaConfig.get_default ();
            try {
                allow_upload = config.get_allow_upload ();
            } catch (Error error) {}

            if (allow_upload) {
                flags |= OCMFlags.UPLOAD | OCMFlags.UPLOAD_DESTROYABLE;
            }

            var allow_deletion = true;
            try {
                allow_deletion = config.get_allow_deletion ();
            } catch (Error error) {}

            if (allow_deletion) {
                flags |= OCMFlags.DESTROYABLE;
            }

            if (this is UpdatableObject) {
                flags |= OCMFlags.CHANGE_METADATA;
            }

            return flags;
        }
    }

    public MediaContainer (string          id,
                           MediaContainer? parent,
                           string          title,
                           int             child_count) {
        this.id = id;
        this.parent = parent;
        this.title = title;
        this.child_count = child_count;
        this.update_id = 0;
        this.storage_used = -1;
        this.total_deleted_child_count = 0;
        this.upnp_class = STORAGE_FOLDER;

        this.container_updated.connect (on_container_updated);
        this.sub_tree_updates_finished.connect (on_sub_tree_updates_finished);
    }

    public MediaContainer.root (string title,
                                int    child_count) {
        this ("0", null, title, child_count);
    }

    /**
     * Fetches the list of media objects directly under this container.
     *
     * @param offset zero-based index of the first item to return
     * @param max_count maximum number of objects to return
     * @param sort_criteria sorting order of objects to return
     * @param cancellable optional cancellable for this operation
     *
     * @return A list of media objects.
     */
    public async abstract MediaObjects? get_children (uint         offset,
                                                      uint         max_count,
                                                      string       sort_criteria,
                                                      Cancellable? cancellable)
                                                      throws Error;

    /**
     * Recursively searches this container for a media object with the given ID.
     *
     * @param id ID of the media object to search for
     * @param cancellable optional cancellable for this operation
     *
     * @return the found media object.
     */
    public async abstract MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error;

    /**
     * This method should be called each time this container is updated.
     *
     * For instance, this should be called if there are metadata changes
     * for this container, if items under it are removed or added, if
     * there are metadata changes to items under it, etc.
     */
    public void updated (MediaObject object = this,
                         ObjectEventType event_type = ObjectEventType.MODIFIED,
                         bool sub_tree_update = false) {
        // Emit the signal that will start the bump-up process for this event.
        this.container_updated (this, object, event_type, sub_tree_update);
    }

    internal override DIDLLiteObject serialize (DIDLLiteWriter writer,
                                                HTTPServer     http_server)
                                                throws Error {
        var didl_container = writer.add_container ();
        if (this.parent != null) {
            didl_container.parent_id = this.parent.id;
        } else {
            didl_container.parent_id = "-1";
        }

        didl_container.id = this.id;
        didl_container.title = this.title;
        didl_container.child_count = this.child_count;
        didl_container.upnp_class = this.upnp_class;
        didl_container.searchable = this is SearchableContainer;
        didl_container.storage_used = this.storage_used;
        if (this is TrackableContainer) {
            didl_container.container_update_id = this.update_id;
            didl_container.update_id = this.object_update_id;
            didl_container.total_deleted_child_count =
                                        (uint) this.total_deleted_child_count;
        }

        if (this.parent == null && (this is SearchableContainer)) {
            (this as SearchableContainer).serialize_search_parameters
                                        (didl_container);
        }

        if (!this.restricted) {
            didl_container.restricted = false;
            didl_container.dlna_managed = this.ocm_flags;

            var writable = this as WritableContainer;
            foreach (var create_class in writable.create_classes) {
                didl_container.add_create_class (create_class);
            }
        } else {
            didl_container.restricted = true;
        }

        return didl_container;
    }

    /**
     * handler for container_updated signal on this container. We only forward
     * it to the parent, hoping someone will get it from the root container
     * and act upon it.
     *
     * @param container the container that emitted the signal
     * @param updated_container the container that just got updated
     */
    private void on_container_updated (MediaContainer container,
                                       MediaContainer updated_container,
                                       MediaObject object,
                                       ObjectEventType event_type,
                                       bool sub_tree_update) {
        if (this.parent != null) {
            this.parent.container_updated (updated_container,
                                           object,
                                           event_type,
                                           sub_tree_update);
        }
    }

    private void on_sub_tree_updates_finished (MediaContainer container,
                                               MediaObject sub_tree_root) {
        if (this.parent != null) {
            this.parent.sub_tree_updates_finished (sub_tree_root);
        }
    }
}
