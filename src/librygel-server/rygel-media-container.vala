/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 MediaNet Inh.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
 *          Craig Pratt <craig@ecaspia.com>
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

public enum Rygel.ObjectEventType {
    ADDED = 0,
    MODIFIED = 1,
    DELETED = 2
}

/**
 * Implementation of RygelDataSource to serve generated playlists to a client.
 */
internal class Rygel.PlaylistDatasource : Rygel.DataSource, Object {
    private MediaContainer container;
    private uint8[] data;
    private HTTPServer server;
    private ClientHacks hacks;
    private SerializerType playlist_type;

    public PlaylistDatasource (SerializerType playlist_type,
                               MediaContainer container,
                               HTTPServer     server,
                               ClientHacks?   hacks) {
        this.playlist_type = playlist_type;
        this.container = container;
        this.server = server;
        this.hacks = hacks;
        this.generate_data.begin ();
    }

    public signal void data_ready ();

    public Gee.List<HTTPResponseElement>? preroll
                                        (HTTPSeekRequest? seek_request,
                                         PlaySpeedRequest? playspeed_request)
                                         throws Error {
        if (seek_request != null) {
            throw new DataSourceError.SEEK_FAILED
                                        (_("Seeking not supported"));
        }

        if (playspeed_request != null) {
            throw new DataSourceError.PLAYSPEED_FAILED
                                    (_("Speed not supported"));
        }

        return null;
    }

    public void start () throws Error {
        if (this.data == null) {
            this.data_ready.connect ( () => {
                try {
                    this.start ();
                } catch (Error error) { }
            });

            return;
        }

        Idle.add ( () => {
            this.data_available (this.data);
            this.done ();

            return false;
        });
    }

    public void freeze () { }

    public void thaw () { }

    public void stop () { }

    public async void generate_data () {
        try {
            var sort_criteria = this.container.sort_criteria;
            var count = this.container.child_count;

            var children = yield this.container.get_children (0,
                                                              count,
                                                              sort_criteria,
                                                              null);

            if (children != null) {
                var serializer = new Serializer (this.playlist_type);
                children.serialize (serializer, this.server, this.hacks);

                var xml = serializer.get_string ();

                this.data = xml.data;
                this.data_ready ();
            } else {
                this.error (new DataSourceError.GENERAL
                                        (_("Failed to generate playlist")));
            }
        } catch (Error error) {
            warning ("Could not generate playlist: %s", error.message);
            this.error (error);
        }
    }
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

    private const string DIDL_S_PLAYLIST_RESNAME = "didl_s_playlist";
    private const string M3U_PLAYLIST_RESNAME = "m3u_playlist";

    public static bool equal_func (MediaContainer a, MediaContainer b) {
        return a.id == b.id;
    }

    /**
     * The container_updated signal is emitted if the subtree unter this
     * container has been modified. The object parameter is set to
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
            if (!(this is WritableContainer) || this.get_uris ().is_empty) {
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
    protected MediaContainer (string          id,
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
    protected MediaContainer.root (string title,
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

        this.container_updated.connect (this.on_container_updated);
        this.sub_tree_updates_finished.connect
                                        (this.on_sub_tree_updates_finished);
        this.add_playlist_resources ();
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


    /**
     * Add playlist resources to the MediaObject resource list
     */
    internal void add_playlist_resources () {
        { // Create the DIDL_S playlist resource
            var didl_s_res = new MediaResource (DIDL_S_PLAYLIST_RESNAME);
            didl_s_res.extension = "xml";
            didl_s_res.mime_type = "text/xml";
            didl_s_res.dlna_profile = "DIDL_S";
            didl_s_res.dlna_flags = DLNAFlags.CONNECTION_STALL |
                                    DLNAFlags.BACKGROUND_TRANSFER_MODE |
                                    DLNAFlags.INTERACTIVE_TRANSFER_MODE;
            didl_s_res.uri = ""; // Established during serialization
            this.get_resource_list ().add (didl_s_res);
        }

        { // Create the M3U playlist resource
            var m3u_res = new MediaResource (M3U_PLAYLIST_RESNAME);
            m3u_res.extension = "m3u";
            m3u_res.mime_type = "audio/x-mpegurl";
            m3u_res.dlna_profile = null;
            m3u_res.dlna_flags = DLNAFlags.CONNECTION_STALL |
                                 DLNAFlags.BACKGROUND_TRANSFER_MODE |
                                 DLNAFlags.INTERACTIVE_TRANSFER_MODE;
            m3u_res.uri = ""; // Established during serialization
            this.get_resource_list ().add (m3u_res);
        }
    }

    public override DIDLLiteObject? serialize (Serializer serializer,
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
        if (this.child_count > -1) {
            didl_container.child_count = this.child_count;
        }
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
            ((SearchableContainer) this).serialize_search_parameters
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

        if (this.child_count > 0) {
            this.serialize_resource_list (didl_container, http_server);
        }

        return didl_container;
    }

    public override DataSource? create_stream_source_for_resource
                                         (HTTPRequest request,
                                          MediaResource resource)
                                          throws Error {
        SerializerType playlist_type;

        switch (resource.get_name ()) {
            case DIDL_S_PLAYLIST_RESNAME:
                playlist_type = SerializerType.DIDL_S;
                break;
            case M3U_PLAYLIST_RESNAME:
                playlist_type = SerializerType.M3UEXT;
                break;
            default:
                warning (_("Unknown MediaContainer resource: %s"), resource.get_name ());

                return null;
        }

        return new PlaylistDatasource (playlist_type,
                                       this,
                                       request.http_server,
                                       request.hack);
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
