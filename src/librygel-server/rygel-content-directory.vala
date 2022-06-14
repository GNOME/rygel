/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
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

/**
 * Errors used by ContentDirectory and deriving classes.
 */
internal errordomain Rygel.ContentDirectoryError {
    NO_SUCH_OBJECT = 701,
    INVALID_CURRENT_TAG_VALUE = 702,
    INVALID_NEW_TAG_VALUE = 703,
    REQUIRED_TAG = 704,
    READ_ONLY_TAG = 705,
    PARAMETER_MISMATCH = 706,
    INVALID_SEARCH_CRITERIA = 708,
    INVALID_SORT_CRITERIA = 709,
    NO_SUCH_CONTAINER = 710,
    RESTRICTED_OBJECT = 711,
    BAD_METADATA = 712,
    RESTRICTED_PARENT = 713,
    NO_SUCH_FILE_TRANSFER = 717,
    NO_SUCH_DESTINATION_RESOURCE = 718,
    CANT_PROCESS = 720,
    OUTDATED_OBJECT_METADATA = 728,
    INVALID_ARGS = 402
}

/**
 * Basic implementation of UPnP ContentDirectory service version 2. Most often
 * plugins will provide a child of this class. The inheriting classes should
 * override create_root_container method.
 */
public class Rygel.ContentDirectory: Service {
    public const string UPNP_ID = "urn:upnp-org:serviceId:ContentDirectory";
    public const string UPNP_TYPE =
                    "urn:schemas-upnp-org:service:ContentDirectory:3";
    public const string UPNP_TYPE_V1 =
                    "urn:schemas-upnp-org:service:ContentDirectory:1";
    public const string DESCRIPTION_PATH = "xml/ContentDirectory.xml";
    public const string DESCRIPTION_PATH_NO_TRACK =
                    "xml/ContentDirectory-NoTrack.xml";

    protected string feature_list;

    internal HTTPServer http_server;

    public MediaContainer root_container;
    private ArrayList<MediaContainer> updated_containers;

    private ArrayList<ImportResource> active_imports;
    private ArrayList<ImportResource> finished_imports;

    private bool clear_updated_containers;
    private uint update_notify_id;

    internal Cancellable cancellable;

    public uint32 system_update_id;

    private LastChange last_change;

    private string service_reset_token;

    public override void constructed () {
        base.constructed ();

        this.cancellable = new Cancellable ();

        var plugin = this.root_device.resource_factory as MediaServerPlugin;

        this.root_container = plugin.root_container;
        this.http_server = new HTTPServer (this, plugin.name);

        this.updated_containers = new ArrayList<MediaContainer>
                                        (MediaContainer.equal_func);
        this.active_imports = new ArrayList<ImportResource> ();
        this.finished_imports = new ArrayList<ImportResource> ();

        if (this.root_container is TrackableContainer) {
            var trackable = this.root_container as TrackableContainer;
            this.service_reset_token = trackable.get_service_reset_token ();
            this.system_update_id = trackable.get_system_update_id ();
        } else {
            this.service_reset_token = Uuid.string_random ();
            this.system_update_id = 0;
        }

        this.root_container.container_updated.connect (on_container_updated);
        this.root_container.sub_tree_updates_finished.connect
                                        (on_sub_tree_updates_finished);

        this.last_change = new LastChange ();

        this.feature_list =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Features xmlns=\"urn:schemas-upnp-org:av:avs\" " +
            "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
            "xsi:schemaLocation=\"urn:schemas-upnp-org:av:avs" +
            "http://www.upnp.org/schemas/av/avs-v1-20060531.xsd\">" +
            "</Features>";

        this.action_invoked["Browse"].connect (this.browse_cb);
        this.action_invoked["Search"].connect (this.search_cb);
        this.action_invoked["CreateObject"].connect (this.create_object_cb);
        this.action_invoked["CreateReference"].connect
                                        (this.create_reference_cb);
        this.action_invoked["DestroyObject"].connect (this.destroy_object_cb);
        this.action_invoked["UpdateObject"].connect (this.update_object_cb);
        this.action_invoked["ImportResource"].connect (this.import_resource_cb);
        this.action_invoked["GetTransferProgress"].connect (
                                        this.get_transfer_progress_cb);
        this.action_invoked["StopTransferResource"].connect (
                                        this.stop_transfer_resource_cb);

        this.action_invoked["X_GetDLNAUploadProfiles"].connect
                                        (this.get_dlna_upload_profiles_cb);

        this.query_variable["TransferIDs"].connect (this.query_transfer_ids);

        /* Connect SystemUpdateID related signals */
        this.action_invoked["GetSystemUpdateID"].connect (
                                        this.get_system_update_id_cb);
        this.query_variable["SystemUpdateID"].connect (
                                        this.query_system_update_id);
        this.query_variable["ContainerUpdateIDs"].connect (
                                        this.query_container_update_ids);

        /* Connect SearchCapabilities related signals */
        this.action_invoked["GetSearchCapabilities"].connect (
                                        this.get_search_capabilities_cb);
        this.query_variable["SearchCapabilities"].connect (
                                        this.query_search_capabilities);

        /* Connect SortCapabilities related signals */
        this.action_invoked["GetSortCapabilities"].connect (
                                        this.get_sort_capabilities_cb);
        this.query_variable["SortCapabilities"].connect (
                                        this.query_sort_capabilities);

        /* Connect FeatureList related signals */
        this.action_invoked["GetFeatureList"].connect (
                                        this.get_feature_list_cb);
        this.query_variable["FeatureList"].connect (this.query_feature_list);

        /* Connect LastChange related signals */
        this.query_variable["LastChange"].connect (this.query_last_change);

        /* Connect ServiceResetToken related signals */
        this.query_variable["ServiceResetToken"].connect
                                        (this.query_service_reset_token);
        this.action_invoked["GetServiceResetToken"].connect
                                        (this.get_service_reset_token_cb);

        this.http_server.run.begin ();
    }

    ~ContentDirectory () {
        // Cancel all state machines
        this.cancellable.cancel ();
    }

    /* Browse action implementation */
    private void browse_cb (Service       content_dir,
                            ServiceAction action) {
        Browse browse = new Browse (this, action);

        browse.run.begin ();
    }

    /* Search action implementation */
    private void search_cb (Service       content_dir,
                            ServiceAction action) {
        var search = new Search (this, action);

        search.run.begin ();
    }

    /* CreateObject action implementation */
    private void create_object_cb (Service       content_dir,
                                   ServiceAction action) {
        var creator = new ObjectCreator (this, action);

        creator.run.begin ();
    }

    /* CreateReference action implementation */
    private void create_reference_cb (Service       content_dir,
                                      ServiceAction action) {
        var creator = new ReferenceCreator (this, action);

        creator.run.begin ();
    }

    /* DestroyObject action implementation */
    private void destroy_object_cb (Service       content_dir,
                                    ServiceAction action) {
        var destroyer = new ItemDestroyer (this, action);

        destroyer.run.begin ();
    }

    /* UpdateObject action implementation */
    private void update_object_cb (Service       content_dir,
                                   ServiceAction action) {
        var updater = new ItemUpdater (this, action);

        updater.run.begin ();
    }

    /* ImportResource action implementation */
    private void import_resource_cb (Service       content_dir,
                                     ServiceAction action) {
        var import = new ImportResource (this, action);

        import.completed.connect (this.on_import_completed);
        this.active_imports.add (import);

        import.run.begin ();

        this.notify ("TransferIDs",
                        typeof (string),
                        this.create_transfer_ids ());
    }

    /* Query TransferIDs */
    private void query_transfer_ids (Service          content_dir,
                                     string           variable,
                                     ref GLib.Value   value) {
        value.init (typeof (string));
        value.set_string (this.create_transfer_ids ());
    }

    /* GetTransferProgress action implementation */
    private void get_transfer_progress_cb (Service       content_dir,
                                           ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        try {
            var import = this.find_import_for_action (action);

            action.set ("TransferStatus",
                            typeof (string),
                            import.status_as_string,
                        "TransferLength",
                            typeof (int64),
                            import.bytes_copied,
                        "TransferTotal",
                            typeof (int64),
                            import.bytes_total);

            action.return_success ();
        } catch (Error error) {
            action.return_error (error.code, error.message);
        }
    }

    /* StopTransferResource action implementation */
    private void stop_transfer_resource_cb (Service       content_dir,
                                            ServiceAction action) {
        if (action.get_argument_count () != 1) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        try {
            var import = find_import_for_action (action);
            import.cancellable.cancel ();

            action.return_success ();
        } catch (Error error) {
            action.return_error (error.code, error.message);
        }
    }

    /* GetSystemUpdateID action implementation */
    private void get_system_update_id_cb (Service       content_dir,
                                          ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        /* Set action return arguments */
        action.set ("Id", typeof (uint32), this.system_update_id);

        action.return_success ();
    }

    /* Query GetSystemUpdateID */
    private void query_system_update_id (Service        content_dir,
                                         string         variable,
                                         ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (uint32));
        value.set_uint (this.system_update_id);
    }

    /* Query ContainerUpdateIDs */
    private void query_container_update_ids (Service        content_dir,
                                             string         variable,
                                             ref GLib.Value value) {
        var update_ids = this.create_container_update_ids ();

        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (update_ids);
    }

    /* action GetSearchCapabilities implementation */
    private void get_search_capabilities_cb (Service       content_dir,
                                             ServiceAction action) {
        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        var plugin = this.root_device.resource_factory as MediaServerPlugin;

        /* Set action return arguments */
        action.set ("SearchCaps", typeof (string), plugin.search_caps);

        action.return_success ();
    }

    /* Query SearchCapabilities */
    private void query_search_capabilities (Service        content_dir,
                                            string         variable,
                                            ref GLib.Value value) {
        var plugin = this.root_device.resource_factory as MediaServerPlugin;

        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (plugin.search_caps);
    }

    /* action GetSortCapabilities implementation */
    private void get_sort_capabilities_cb (Service       content_dir,
                                           ServiceAction action) {

        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        /* Set action return arguments */
        action.set ("SortCaps", typeof (string), MediaObjects.SORT_CAPS);

        action.return_success ();
    }

    /* Query SortCapabilities */
    private void query_sort_capabilities (Service        content_dir,
                                          string         variable,
                                          ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (MediaObjects.SORT_CAPS);
    }

    /* action GetFeatureList implementation */
    private void get_feature_list_cb (Service       content_dir,
                                      ServiceAction action) {

        if (action.get_argument_count () != 0) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        /* Set action return arguments */
        action.set ("FeatureList", typeof (string), this.feature_list);

        action.return_success ();
    }

    /* Query FeatureList */
    private void query_feature_list (Service        content_dir,
                                     string         variable,
                                     ref GLib.Value value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (this.feature_list);
    }

    private string create_container_update_ids () {
        var update_ids = "";

        foreach (var container in this.updated_containers) {
            if (update_ids != "") {
                update_ids += ",";
            }

            update_ids += container.id + "," + container.update_id.to_string ();
        }

        return update_ids;
    }

    private bool handle_system_update () {
        var plugin = this.root_device.resource_factory as MediaServerPlugin;

        // We can increment this uint32 variable unconditionally
        // because unsigned overflow (as compared to signed overflow)
        // is well defined.
        this.system_update_id++;
        if (this.system_update_id == 0 &&
            PluginCapabilities.TRACK_CHANGES in plugin.capabilities) {
            // Overflow, need to initiate Service Reset Procedure.
            // See ContentDirectory:3 spec, 2.3.7.1
            this.service_reset.begin ();

            return true;
        }

        return false;
    }

    private void handle_last_change (MediaContainer updated_container,
                                     MediaObject object,
                                     ObjectEventType event_type,
                                     bool sub_tree_update) {
        if (updated_container is TrackableContainer) {
            this.add_last_change_entry (object, event_type, sub_tree_update);
        }
    }

    private bool set_update_ids (MediaContainer updated_container,
                                 MediaObject object,
                                 ObjectEventType event_type) {
        bool container_changed = false;

        if (event_type == ObjectEventType.ADDED ||
            event_type == ObjectEventType.DELETED ||
            (event_type == ObjectEventType.MODIFIED &&
             object is MediaItem)) {
            updated_container.update_id = this.system_update_id;
            container_changed = true;
        }

        object.object_update_id = this.system_update_id;
        // Whenever container experiences object update it also
        // experiences a container update

        var container = object as MediaContainer;
        if (container != null) {
            container.update_id = this.system_update_id;
        }

        return container_changed;
    }

    private void handle_container_update_ids (MediaContainer? updated_container,
                                              MediaObject object) {
        var updated = updated_container != null;
        var is_container = object is MediaContainer;

        if (!updated && !is_container) {
            return;
        }

        if (this.clear_updated_containers) {
            this.updated_containers.clear ();
            this.clear_updated_containers = false;
        }

        // UPnP specs dicate we make sure only last update be evented
        if (updated) {
            this.updated_containers.remove (updated_container);
            this.updated_containers.add (updated_container);
        }

        if (is_container) {
            MediaContainer container = object as MediaContainer;

            this.updated_containers.remove (container);
            this.updated_containers.add (container);
        }
    }

    /**
     * handler for container_updated signal on root_container. We don't
     * immediately send the notification for changes but schedule the
     * notification after 0.2 seconds. Also we don't clear the updated
     * container list immediately after notification but rather in this
     * function. Please refer to ContentDirectory version 2 specs for details
     * on why we do all this the way we do.
     *
     * @param root_container the root_container
     * @param updated_container the container that just got updated
     */
    private void on_container_updated (MediaContainer root_container,
                                       MediaContainer updated_container,
                                       MediaObject object,
                                       ObjectEventType event_type,
                                       bool sub_tree_update) {
        if (handle_system_update ()) {
            return;
        }
        handle_last_change (updated_container,
                            object,
                            event_type,
                            sub_tree_update);

        var changed = set_update_ids (updated_container, object, event_type);
        handle_container_update_ids (changed ? updated_container : null,
                                     object);

        this.ensure_timeout ();
    }

    private void on_sub_tree_updates_finished (MediaContainer root_container,
                                               MediaObject sub_tree_root)
    {

        var entry = new LastChangeStDone (sub_tree_root.id,
                                          this.system_update_id);

        this.last_change.add_event (entry);
        this.ensure_timeout ();
    }

    private bool update_notify () {
        var update_ids = this.create_container_update_ids ();

        this.notify ("ContainerUpdateIDs", typeof (string), update_ids);
        this.notify ("SystemUpdateID", typeof (uint32), this.system_update_id);
        this.notify ("LastChange", typeof (string), this.last_change.get_log ());

        this.clear_updated_containers = true;
        this.update_notify_id = 0;
        this.last_change.clear_on_new_event ();

        return false;
    }

    private string create_transfer_ids () {
        var ids = "";

        foreach (var import in this.active_imports) {
            if (ids != "") {
                ids += ",";
            }

            ids += import.transfer_id.to_string ();
        }

        return ids;
    }

    private void on_import_completed (StateMachine machine) {
        var import = machine as ImportResource;

        this.finished_imports.add (import);
        this.active_imports.remove (import);

        // signal the end of transfer
        this.notify ("TransferIDs",
                        typeof (string),
                        this.create_transfer_ids ());

        // According to CDS specs (v3 section 2.4.17), we must not immediately
        // remove the import from out memory
        Timeout.add_seconds (30, () => {
                this.finished_imports.remove (import);

                return false;
        });
    }

    private ImportResource? find_import_for_action (ServiceAction action)
                                            throws ContentDirectoryError {
        ImportResource ret = null;
        uint32 transfer_id;
        string transfer_id_string;

        // TODO: Remove string hack once bgo#705516 is fixed
        action.get ("TransferID",
                        typeof (uint32),
                        out transfer_id,
                    "TransferID",
                        typeof (string),
                        out transfer_id_string);
        if (transfer_id == 0 &&
            (transfer_id_string == null || transfer_id_string != "0")) {
            throw new ContentDirectoryError.INVALID_ARGS
                                        (_("Invalid argument"));
        }

        foreach (var import in this.active_imports) {
            if (import.transfer_id == transfer_id) {
                ret = import;

                break;
            }
        }

        foreach (var import in this.finished_imports) {
            if (import.transfer_id == transfer_id) {
                ret = import;

                break;
            }
        }

        if (ret == null) {
            throw new ContentDirectoryError.NO_SUCH_FILE_TRANSFER
                                        (_("No such file transfer"));
        }

        return ret;
    }

    /* Query LastChange */
    private void query_last_change (Service          content_dir,
                                    string           variable,
                                    ref GLib.Value   value) {
        value.init (typeof (string));
        value.set_string (this.last_change.get_log ());
    }

    private void ensure_timeout () {
        if (this.update_notify_id == 0) {
            this.update_notify_id = Timeout.add (200, this.update_notify);
        }
    }

    private void add_last_change_entry (MediaObject object,
                                        ObjectEventType event_type,
                                        bool sub_tree_update) {
        LastChangeEntry entry;

        switch (event_type) {
        case ObjectEventType.ADDED:
            entry = new LastChangeObjAdd (object.id,
                                          this.system_update_id,
                                          sub_tree_update,
                                          object.parent.id,
                                          object.upnp_class);
            break;

        case ObjectEventType.MODIFIED:
            entry = new LastChangeObjMod (object.id,
                                          this.system_update_id,
                                          sub_tree_update);
            break;

        case ObjectEventType.DELETED:
            entry = new LastChangeObjDel (object.id,
                                          this.system_update_id,
                                          sub_tree_update);
            break;

        default:
            assert_not_reached ();
        }

        this.last_change.add_event (entry);
    }

    /* ServiceResetToken */
    private void get_service_reset_token_cb (Service       content_dir,
                                             ServiceAction action) {
        action.set ("ResetToken", typeof (string), this.service_reset_token);
        action.return_success ();
    }

    private void query_service_reset_token (Service        content_dir,
                                            string         variable,
                                            ref GLib.Value value) {
        value.init (typeof (string));
        value.set_string (this.service_reset_token);
    }

    private async void service_reset () {
        debug ("SystemUpdateID overflow, initiating service reset procedure");

        var plugin = this.root_device.resource_factory as MediaServerPlugin;
        plugin.active = false;
        this.service_reset_token = Uuid.string_random ();
        if (this.root_container is TrackableContainer) {
            var trackable = this.root_container as TrackableContainer;
            trackable.set_service_reset_token (this.service_reset_token);
        }

        var expression = new RelationalExpression ();
        expression.operand1 = "upnp:objectUpdateID";
        expression.operand2 = "true";
        expression.op = SearchCriteriaOp.EXISTS;

        try {
            var root = this.root_container as SearchableContainer;
            if (root == null) {
                // TODO:
                return;
            }

            uint32 matches = 0;
            var objects = yield root.search (expression,
                                             0,
                                             0,
                                             "",
                                             null,
                                             out matches);
            if (objects.size > 0) {
                uint32 count = 1;
                foreach (var object in objects) {
                    object.object_update_id = count++;

                    if (object is TrackableContainer) {
                        var container = object as MediaContainer;
                        container.update_id = container.object_update_id;
                        container.total_deleted_child_count = 0;
                    }
                }

                // SystemUpdateID needs to be the highest object_update_id
                this.system_update_id = count - 1;
                debug ("New SystemUpdateID is %u", this.system_update_id);
            }

            debug ("Service reset procedure done, device coming up again");
            plugin.active = true;
            debug ("New service reset token is %s", this.service_reset_token);
        } catch (Error error) { warning ("Failed to search for objects..."); };
    }

    /* X_GetDLNAUploadProfiles action implementation */
    private void get_dlna_upload_profiles_cb (Service       content_dir,
                                              ServiceAction action) {
        string upload_profiles = null;

        action.get ("UploadProfiles", typeof (string), out upload_profiles);

        if (upload_profiles == null) {
            action.return_error (402, _("Invalid argument"));

            return;
        }

        var plugin = this.root_device.resource_factory as MediaServerPlugin;
        unowned GLib.List<DLNAProfile> profiles = plugin.upload_profiles;
        var requested_profiles = upload_profiles.split (",");
        var builder = new StringBuilder ();
        foreach (var profile in profiles) {
            // Skip forbidden profiles
            if (profile.name.has_suffix ("_ICO") ||
                profile.name.has_suffix ("_TN") ||
                profile.name == "DIDL_S") {
                continue;
            }

            if (requested_profiles.length == 0 ||
                profile.name in requested_profiles) {
                builder.append (profile.name);
                builder.append (",");
            }
        }

        if (builder.len > 0) {
            builder.truncate (builder.len - 1);
        }

        action.set ("SupportedUploadProfiles", typeof (string), builder.str);
        action.return_success ();
    }
}
