/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
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
 * Errors used by ContentDirectory and deriving classes.
 */
public errordomain Rygel.ContentDirectoryError {
    NO_SUCH_OBJECT = 701,
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
                    "urn:schemas-upnp-org:service:ContentDirectory:2";
    public const string DESCRIPTION_PATH = "xml/ContentDirectory.xml";

    protected string feature_list;
    protected string search_caps;
    protected string sort_caps;

    internal HTTPServer http_server;

    public MediaContainer root_container;
    private ArrayList<MediaContainer> updated_containers;

    private bool clear_updated_containers;
    private uint update_notify_id;

    private ArrayList<Browse> browses;
    internal Cancellable cancellable;

    public uint32 system_update_id;

    // Public abstract methods derived classes need to implement
    public virtual MediaContainer? create_root_container () {
       return null;
    }

    public override void constructed () {
        this.cancellable = new Cancellable ();

        this.root_container = this.create_root_container ();
        this.http_server = new HTTPServer (this, this.get_type ().name ());

        this.browses = new ArrayList<Browse> ();
        this.updated_containers =  new ArrayList<MediaContainer> ();

        this.root_container.container_updated += on_container_updated;

        this.feature_list =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<Features xmlns=\"urn:schemas-upnp-org:av:avs\" " +
            "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
            "xsi:schemaLocation=\"urn:schemas-upnp-org:av:avs" +
            "http://www.upnp.org/schemas/av/avs-v1-20060531.xsd\">" +
            "</Features>";
        this.search_caps = "";
        this.sort_caps = "";

        this.action_invoked["Browse"] += this.browse_cb;

        /* Connect SystemUpdateID related signals */
        this.action_invoked["GetSystemUpdateID"] +=
                                                this.get_system_update_id_cb;
        this.query_variable["SystemUpdateID"] += this.query_system_update_id;
        this.query_variable["ContainerUpdateIDs"] +=
                                                this.query_container_update_ids;

        /* Connect SearchCapabilities related signals */
        this.action_invoked["GetSearchCapabilities"] +=
                                                this.get_search_capabilities_cb;
        this.query_variable["SearchCapabilities"] +=
                                                this.query_search_capabilities;

        /* Connect SortCapabilities related signals */
        this.action_invoked["GetSortCapabilities"] +=
                                                this.get_sort_capabilities_cb;
        this.query_variable["SortCapabilities"] +=
                                                this.query_sort_capabilities;

        /* Connect FeatureList related signals */
        this.action_invoked["GetFeatureList"] += this.get_feature_list_cb;
        this.query_variable["FeatureList"] += this.query_feature_list;

        this.http_server.run (this.cancellable);
    }

    ~ContentDirectory () {
        // Cancel all state machines
        this.cancellable.cancel ();
    }

    /* Browse action implementation */
    private virtual void browse_cb (ContentDirectory    content_dir,
                                    owned ServiceAction action) {
        Browse browse = new Browse (this, action);

        this.browses.add (browse);
        browse.completed += this.on_browse_completed;

        browse.run (this.cancellable);
    }

    /* GetSystemUpdateID action implementation */
    private void get_system_update_id_cb (ContentDirectory    content_dir,
                                          owned ServiceAction action) {
        /* Set action return arguments */
        action.set ("Id", typeof (uint32), this.system_update_id);

        action.return ();
    }

    /* Query GetSystemUpdateID */
    private void query_system_update_id (ContentDirectory content_dir,
                                         string           variable,
                                         ref GLib.Value   value) {
        /* Set action return arguments */
        value.init (typeof (uint32));
        value.set_uint (this.system_update_id);
    }

    /* Query ContainerUpdateIDs */
    private void query_container_update_ids (ContentDirectory content_dir,
                                             string           variable,
                                             ref GLib.Value   value) {
        var update_ids = this.create_container_update_ids ();

        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (update_ids);
    }

    /* action GetSearchCapabilities implementation */
    private void get_search_capabilities_cb (ContentDirectory    content_dir,
                                             owned ServiceAction action) {
        /* Set action return arguments */
        action.set ("SearchCaps", typeof (string), this.search_caps);

        action.return ();
    }

    /* Query SearchCapabilities */
    private void query_search_capabilities (ContentDirectory content_dir,
                                            string           variable,
                                            ref GLib.Value   value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (this.search_caps);
    }

    /* action GetSortCapabilities implementation */
    private void get_sort_capabilities_cb (ContentDirectory    content_dir,
                                           owned ServiceAction action) {
        /* Set action return arguments */
        action.set ("SortCaps", typeof (string), this.sort_caps);

        action.return ();
    }

    /* Query SortCapabilities */
    private void query_sort_capabilities (ContentDirectory content_dir,
                                          string           variable,
                                          ref GLib.Value   value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (this.sort_caps);
    }

    /* action GetFeatureList implementation */
    private void get_feature_list_cb (ContentDirectory    content_dir,
                                      owned ServiceAction action) {
        /* Set action return arguments */
        action.set ("FeatureList", typeof (string), this.feature_list);

        action.return ();
    }

    /* Query FeatureList */
    private void query_feature_list (ContentDirectory content_dir,
                                     string           variable,
                                     ref GLib.Value   value) {
        /* Set action return arguments */
        value.init (typeof (string));
        value.set_string (this.feature_list);
    }

    private void on_browse_completed (Browse browse) {
        this.browses.remove (browse);
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
                                       MediaContainer updated_container) {
        this.system_update_id++;

        if (this.clear_updated_containers) {
            this.updated_containers.clear ();
            this.clear_updated_containers = false;
        }

        // UPnP specs dicate we make sure only last update be evented
        this.updated_containers.remove (updated_container);
        this.updated_containers.add (updated_container);

        if (this.update_notify_id == 0) {
            this.update_notify_id = Timeout.add (200, this.update_notify);
        }
    }

    private bool update_notify () {
        var update_ids = this.create_container_update_ids ();

        this.notify ("ContainerUpdateIDs", typeof (string), update_ids);
        this.notify ("SystemUpdateID", typeof (uint32), this.system_update_id);

        this.clear_updated_containers = true;
        this.update_notify_id = 0;

        return false;
    }
}

