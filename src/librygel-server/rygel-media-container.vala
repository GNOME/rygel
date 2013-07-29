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
 *
 * When used as a root container, you may wish to use the variables, such as
 * REALNAME, in in the title. See the title property of the #RygelMediaObject.
 *
 * If the container should support UPnP search operations then you also implement
 * the #RygelSearchableContainer interface.
 *
 * If the container should be writable, meaning that it allows adding (via upload),
 * removal and editing of items then you should also implement the #RygelWritableContainer
 * interface.
 *
 * If the container should support the change tracking profile of the UPnP
 * ContentDirectory:3 specification then you should also implement the 
 * #RygelTrackableContainer interface.
 *
 * The #RygelSimpleContainer class contains a simple memory-based container
 * implementation, but most real-world uses will require custom container
 * implementations.
 */
public abstract class Rygel.MediaContainer : MediaObject {
    // Magic ID used by DLNA to denote any container that can create the item
    public const string ANY = "DLNA.ORG_AnyContainer";
    public const string UPNP_CLASS = "object.container";
    public const string STORAGE_FOLDER = UPNP_CLASS + ".storageFolder";
    public const string MUSIC_ALBUM = UPNP_CLASS + ".album.musicAlbum";
    public const string MUSIC_ARTIST = UPNP_CLASS + ".person.musicArtist";
    public const string MUSIC_GENRE = UPNP_CLASS + ".genre.musicGenre";
    public const string PLAYLIST = UPNP_CLASS + ".playlistContainer";

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
     * tree of this container has been updated. The object parameter is set to
     * the MediaObject that is the source of the container update. Note that
     * it may even be set to the container itself.
     *
     * @see rygel_media_container_updated().
     *
     * @param container The child container that has been updated.
     * @param object The object that has changed. This may be the container itself, or a child item.
     * @param event_type This describes what actually happened to the object.
     * @param sub_tree_update Whether the modification is part of a sub-tree update. See the #RygelMediaContainer::sub_tree_updates_finished signal.
     */
    public signal void container_updated (MediaContainer container,
                                          MediaObject object,
                                          ObjectEventType event_type,
                                          bool sub_tree_update);

    /**
     * The sub_tree_updates_finished signal is emitted when all of
     * the sub-tree operations are finished.
     * See the #RygelMediaContainer::container_updated signal.
     *
     * @param sub_tree_root - root of a sub-tree where all operations
     * were performed.
     */
    public signal void sub_tree_updates_finished (MediaObject sub_tree_root);

    public int child_count { get; set construct; }
    protected int empty_child_count { get; set; }
    public int all_child_count {
        get {
            return this.child_count + this.empty_child_count;
        }
    }
    public uint32 update_id;
    public int64 storage_used;

    public bool create_mode_enabled { get; set; }

    // This is an uint32 in UPnP. SystemUpdateID should reach uint32.MAX way
    // before this variable and cause a SystemResetProcedure.
    public int64 total_deleted_child_count;

    public string sort_criteria { set; get; default = DEFAULT_SORT_CRITERIA; }

    public override OCMFlags ocm_flags {
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
                flags |= OCMFlags.UPLOAD |
                         OCMFlags.UPLOAD_DESTROYABLE |
                         OCMFlags.CREATE_CONTAINER;
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

    /**
     * Create a media container with the specified details.
     *
     * @param id See the id property of the #RygelMediaObject class.
     * @param parent The parent container, if any.
     * @param title See the title property of the #RygelMediaObject class.
     * @param child_count The initially-known number of child items.
     */
    public MediaContainer (string          id,
                           MediaContainer? parent,
                           string          title,
                           int             child_count) {
        Object (id : id,
                parent : parent,
                title : title,
                child_count : child_count);
    }

    /**
     * Create a root media container with the specified details,
     * with no parent container, and with an appropriate ID.
     *
     * @param title See the title property of the #RygelMediaObject.
     * @param child_count The initially-known number of child items.
     */
    public MediaContainer.root (string title,
                                int    child_count) {
        Object (id : "0",
                parent : null,
                title : title,
                child_count : child_count);
    }

    public override void constructed () {
        base.constructed ();

        this.empty_child_count = 0;
        this.update_id = 0;
        this.storage_used = -1;
        this.total_deleted_child_count = 0;
        this.upnp_class = UPNP_CLASS;
        this.create_mode_enabled = false;

        this.container_updated.connect (on_container_updated);
        this.sub_tree_updates_finished.connect (on_sub_tree_updates_finished);
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
     *
     * If sub_tree_update is true then the caller should later emit the 
     * sub_tree_updates_finished signal on the root container of the sub-tree
     * that was updated.
     *
     * It will eventually result in the server emitting a UPnP LastChange event,
     * though that may be for a batch of these calls.
     *
     * See the #RygelMediaContainer::container_updated signal.
     *
     * @param object The object that has changed, or null to mean the container itself.
     * @param event_type This describes what actually happened to the object.
     * @param sub_tree_update Whether the modification is part of a sub-tree update.
     */
    public void updated (MediaObject? object = null,
                         ObjectEventType event_type = ObjectEventType.MODIFIED,
                         bool sub_tree_update = false) {
        // Emit the signal that will start the bump-up process for this event.
        this.container_updated (this,
                                object != null ? object : this,
                                event_type,
                                sub_tree_update);
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer http_server)
                                                 throws Error {
        var didl_container = serializer.add_container ();
        if (didl_container == null) {
            return null;
        }

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
        if (this.upnp_class == STORAGE_FOLDER) {
            didl_container.storage_used = this.storage_used;
        }

        if (this is TrackableContainer) {
            didl_container.container_update_id = this.update_id;
            didl_container.update_id = this.object_update_id;
            didl_container.total_deleted_child_count =
                                        (uint) this.total_deleted_child_count;
        }

        // If the container is searchable then it must add search class parameters.
        if (this is SearchableContainer) {
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

        this.add_resources (http_server, didl_container);

        return didl_container;
    }

    internal void add_resources (Rygel.HTTPServer http_server,
                                 DIDLLiteContainer didl_container)
                                 throws Error {
        // Add resource with container contents serialized to DIDL_S playlist
        var uri = new HTTPItemURI (this,
                                   http_server,
                                   -1,
                                   -1,
                                   null,
                                   "DIDL_S");
        uri.extension = "xml";

        var res = this.add_resource (didl_container,
                                     uri.to_string (),
                                     http_server.get_protocol ());
        if (res != null) {
            res.protocol_info.mime_type = "text/xml";
            res.protocol_info.dlna_profile = "DIDL_S";
        }

        // Add resource with container contents serialized to M3U playlist
        uri = new HTTPItemURI (this, http_server, -1, -1, null, "M3U");
        uri.extension = "m3u";

        res = this.add_resource (didl_container,
                                 uri.to_string (),
                                 http_server.get_protocol ());
        if (res != null) {
            res.protocol_info.mime_type = "audio/x-mpegurl";
        }
    }

    internal override DIDLLiteResource add_resource
                                        (DIDLLiteObject didl_object,
                                         string?        uri,
                                         string         protocol,
                                         string?        import_uri = null)
                                         throws Error {
        if (this.child_count <= 0) {
            return null as DIDLLiteResource;
        }

        var res = base.add_resource (didl_object,
                                     uri,
                                     protocol,
                                     import_uri);

        if (uri != null) {
            res.uri = uri;
        }

        var protocol_info = new ProtocolInfo ();
        protocol_info.mime_type = "";
        protocol_info.protocol = protocol;
        protocol_info.dlna_flags = DLNAFlags.DLNA_V15 |
                                   DLNAFlags.CONNECTION_STALL |
                                   DLNAFlags.BACKGROUND_TRANSFER_MODE |
                                   DLNAFlags.INTERACTIVE_TRANSFER_MODE;
        res.protocol_info = protocol_info;

        return res;
    }

    /**
     * The handler for the container_updated signal on this container. We only forward
     * it to the parent, hoping someone will get it from the root container
     * and act upon it.
     *
     * @param container The container that emitted the signal
     * @param updated_container The container that just got updated
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

    internal void check_search_expression (SearchExpression? expression) {
        this.create_mode_enabled = false;
        if (expression != null && expression is RelationalExpression) {
            var relational_exp = expression as RelationalExpression;
            if (relational_exp.op == SearchCriteriaOp.DERIVED_FROM &&
                relational_exp.operand1 == "upnp:createClass") {
                this.create_mode_enabled = true;
            }
        }
    }
}
