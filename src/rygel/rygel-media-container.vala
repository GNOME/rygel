/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2010 Nokia Corporation.
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

/**
 * Represents a container (folder) for media items and containers. Provides
 * basic serialization (to DIDLLiteWriter) implementation. Deriving classes
 * are supposed to provide working implementations of get_children.
 */
public abstract class Rygel.MediaContainer : MediaObject {
    public const string UPNP_CLASS = "object.container";
    public const string STORAGE_FOLDER = UPNP_CLASS + ".storageFolder";
    public const string MUSIC_ALBUM = UPNP_CLASS + ".album.musicAlbum";
    public const string MUSIC_ARTIST = UPNP_CLASS + ".person.musicArtist";
    public const string MUSIC_GENRE = UPNP_CLASS + ".genre.musicGenre";

    /**
     * container_updated signal that is emitted if a child container under the
     * tree of this container gets updated.
     *
     * @param container the container that just got updated.
     */
    public signal void container_updated (MediaContainer container);

    public int child_count;
    public uint32 update_id;

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
        this.upnp_class = STORAGE_FOLDER;

        this.container_updated.connect (on_container_updated);
    }

    public MediaContainer.root (string title,
                                int    child_count) {
        this ("0", null, title, child_count);
    }

    /**
     * Fetches the list of media objects directly under this container.
     *
     * @param offet zero-based index of the first item to return
     * @param max_count maximum number of objects to return
     * @param cancellable optional cancellable for this operation
     *
     * return A list of media objects.
     */
    public async abstract MediaObjects? get_children (uint         offset,
                                                      uint         max_count,
                                                      Cancellable? cancellable)
                                                      throws Error;

    /**
     * Recursively searches for media object with the given id in this
     * container.
     *
     * @param id ID of the media object to search for
     * @param cancellable optional cancellable for this operation
     * @param callback function to call when result is ready
     *
     * return the found media object.
     */
    public async abstract MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error;

    /**
     * Method to be be called each time this container is updated (metadata
     * changes for this container, items under it gets removed/added or their
     * metadata changes etc).
     *
     * @param container the container that just got updated.
     */
    public void updated () {
        this.update_id++;

        // Emit the signal that will start the bump-up process for this event.
        this.container_updated (this);
    }

    internal override DIDLLiteObject serialize (DIDLLiteWriter writer,
                                                HTTPServer     http_server)
                                                throws Error {
        var didl_container = writer.add_container ();
        if (this.parent != null) {
            didl_container.parent_id = this.parent.id;
        } else {
            didl_container.parent_id = "-1";
            if (this is SearchableContainer) {
                (this as SearchableContainer).serialize_search_parameters
                                        (didl_container);
            }
        }

        didl_container.id = this.id;
        didl_container.title = this.title;
        didl_container.child_count = this.child_count;
        didl_container.upnp_class = this.upnp_class;
        didl_container.searchable = this is SearchableContainer;

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
                                       MediaContainer updated_container) {
        if (this.parent != null) {
            this.parent.container_updated (updated_container);
        }
    }
}

