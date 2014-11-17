/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
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
 * Represents a media object (container or item).
 *
 * The derived RygelMediaContainer class represents a container
 * and the derived MediaItem classes represent media items.
 */
public abstract class Rygel.MediaObject : GLib.Object {
    private static Regex real_name_regex;
    private static Regex user_name_regex;
    private static Regex host_name_regex;
    private static Regex pretty_name_regex;

    public string id { get; set construct; }
    public string ref_id { get; set; }
    public string upnp_class { get; construct set; }
    public string date { get; set; }
    public string creator { get; set; }
    public uint64 modified { get; set; }
    public uint object_update_id { get; set; }

    public string artist { get; set; }
    public string genre { get; set; }

    //TODO: { get; private set; } or, even better,
    // add virtual set_uri in Object and make add_uri() in Item into set_uri()
    // and make the uri property single-value.
    private Gee.ArrayList<string> uris;

    public Gee.List<string> get_uris () { return this.uris; }

    public string? get_primary_uri () {
        if (this.uris.is_empty) {
            return null;
        }

        return this.uris[0];
    }

    public virtual void add_uri (string uri) {
        this.uris.add (uri);
    }

    private Gee.List<MediaResource> media_resources
                                    = new Gee.LinkedList<MediaResource> ();

    // You can keep both an unowned and owned ref to parent of this MediaObject.
    // In most cases, one will only need to keep an unowned ref to avoid cyclic
    // references since usually the parent container will keep refs to child items.
    // However, in some cases, one only wants the parent to exist as long as the
    // child exists and it is in those cases that you will want to use 'parent_ref'.
    //
    // You must set 'parent' if you set 'parent_ref' but the opposite is not
    // mandatory.
    public unowned MediaContainer parent {
        get {
            return this.parent_ptr;
        }

        set construct {
            this.parent_ptr = value;
        }
    }
    // This one is needed only because external plugin needs to access
    // the address of the parent to add weak pointer.
    public unowned MediaContainer parent_ptr;
    private MediaContainer _parent_ref;
    public MediaContainer parent_ref {
        get {
            return this._parent_ref;
        }

        set {
            this.parent = value;
            this._parent_ref = value;
        }
    }

    private string _title;

    /* Note that the @@ in the doc comment here is a way of escaping @ in valadoc,
     * so the real syntax is, for instance, @REALNAME@, which is what appears in
     * the generated HTML.
     */

    /**
     * The human-readable title of this container or item.
     * These variables will be substituted:
     *
     *  - @@REALNAME@ will be substituted by the user's real name.
     *  - @@USERNAME@ will be substituted by the users's login ID.
     *  - @@HOSTNAME@ will be substituted by the name of the machine.
     *  - @@ADDRESS@ will be substituted by the IP address of network interface used for the UpNP communication.
     *  - @@PRETTY_HOSTNAME@ will be substituted by the human readable name of the machine
     *    (PRETTY_HOSTNAME field of /etc/machine-info)
     */
    public string title {
        get {
            return _title;
        }

        set construct {
            try {
                this._title = real_name_regex.replace_literal
                                        (value,
                                         -1,
                                         0,
                                         Environment.get_real_name ());
                this._title = user_name_regex.replace_literal
                                        (this._title,
                                         -1,
                                         0,
                                         Environment.get_user_name ());
                this._title = host_name_regex.replace_literal
                                        (this._title,
                                         -1,
                                         0,
                                         Environment.get_host_name ());
                this._title = pretty_name_regex.replace_literal
                                        (this._title,
                                         -1,
                                         0,
                                         get_pretty_host_name ());
            } catch (GLib.RegexError err) {
                assert_not_reached ();
            }
        }
    }

    public virtual OCMFlags ocm_flags { get { return OCMFlags.NONE; }}

    internal bool restricted {
        get {
            return this.ocm_flags == OCMFlags.NONE;
        }
    }

    static construct {
        try {
            real_name_regex = new Regex (Regex.escape_string ("@REALNAME@"));
            user_name_regex = new Regex (Regex.escape_string ("@USERNAME@"));
            host_name_regex = new Regex (Regex.escape_string ("@HOSTNAME@"));
            pretty_name_regex = new Regex (Regex.escape_string ("@PRETTY_HOSTNAME@"));
        } catch (GLib.RegexError err) {
            assert_not_reached ();
        }
    }

    public override void constructed () {
        base.constructed ();

        uris = new ArrayList<string> ();
    }

    /**
     * Fetches a File object for any writable URI available for this object.
     *
     * @param cancellable A GLib.Cancellable
     */
    public async File? get_writable (Cancellable? cancellable) throws Error {
        foreach (var uri in this.uris) {
            var file = File.new_for_uri (uri);

            if (yield this.check_writable (file, cancellable)) {
                return file;
            }
        }

        return null;
    }

    /**
     * Fetches File objects for all writable URIs available for this object.
     *
     * @param cancellable A GLib.Cancellable
     */
    public async ArrayList<File> get_writables (Cancellable? cancellable)
                                                throws Error {
        var writables = new ArrayList<File> ();

        foreach (var uri in this.uris) {
            var file = File.new_for_uri (uri);

            if (yield this.check_writable (file, cancellable)) {
                writables.add (file);
            }
        }

        return writables;
    }

    /**
     * Return the MediaResource list.
     */
    public Gee.List<MediaResource> get_resource_list () {
        return media_resources;
    }

    public MediaResource? get_resource_by_name (string resource_name) {
        foreach (var resource in this.media_resources) {
            if (resource.get_name () == resource_name) {
                return resource;
            }
        }

        return null;
    }

    public abstract DIDLLiteObject? serialize (Serializer serializer,
                                               HTTPServer http_server)
                                               throws Error;

    /**
     * Serialize the resource list
     *
     * Any resource with an empty URIs will get a resource-based HTTP URI and have its protocol
     * and delivery options adjusted to the HTTPServer.
     *
     * Internal (e.g. "file:") resources will only be included when the http server
     * is on the local host.
     *
     * Resources will be serialized in list order.
     */
    public void serialize_resource_list (DIDLLiteObject didl_object,
                                         HTTPServer     http_server)
                                         throws Error {
        foreach (var res in this.get_resource_list ()) {
            if (res.uri == null || res.uri == "") {
                res.uri = http_server.create_uri_for_object (this,
                                                             -1,
                                                             -1,
                                                             null,
                                                             res.get_name ());
                var didl_resource = didl_object.add_resource ();
                http_server.set_resource_delivery_options (res);
                res.serialize (didl_resource);
                res.uri = null;
            } else {
                try {
                    var protocol = this.get_protocol_for_uri (res.uri);
                    if (protocol != "internal") {
                        // Exclude internal resources when request is non-local
                        var didl_resource = didl_object.add_resource ();
                        res.serialize (didl_resource);
                    }
                } catch (Error e) {
                    warning (_("Could not determine protocol for %s"), res.uri);
                }
            }
        }
    }

    /**
     * Create a stream source for the given resource
     */
    public abstract DataSource? create_stream_source_for_resource
                                        (HTTPRequest request,
                                         MediaResource resource) throws Error;


    internal virtual void apply_didl_lite (DIDLLiteObject didl_object) {
        this.title = didl_object.title;
        this.artist = this.get_first (didl_object.get_artists ());
        this.genre = didl_object.genre;
    }

    // Recursively drop attributes of a certain namespace from a node.
    private void clean_node (Xml.Node* node, Xml.Ns *ns) {
        var list = new ArrayList<string> ();
        var attr = node->properties;
        while (attr != null) {
            if (attr->ns == ns) {
                list.add (attr->name);
            }

            attr = attr->next;
        }

        foreach (var name in list) {
            node->unset_ns_prop (ns, name);
        }

        var child = node->children;
        while (child != null) {
            this.clean_node (child, ns);
            child = child->next;
        }
    }

    internal async DIDLLiteFragmentResult apply_fragments
                                        (LinkedList<string> current_fragments,
                                         LinkedList<string> new_fragments,
                                         HTTPServer         http_server) {
        var result = DIDLLiteFragmentResult.UNKNOWN_ERROR;

        try {
            var writer = new Serializer (SerializerType.GENERIC_DIDL);
            var didl_object = this.serialize (writer, http_server);

            // Drop dlna:* attribute since it fails XSD validation
            // in gupnp-av. bgo#701637
            this.clean_node (didl_object.xml_node,
                             didl_object.dlna_namespace);

            result = didl_object.apply_fragments
                                        (current_fragments.to_array (),
                                         new_fragments.to_array ());

            if (result == DIDLLiteFragmentResult.OK) {
                this.apply_didl_lite (didl_object);
                if (this is UpdatableObject) {
                    yield (this as UpdatableObject).commit ();
                }
            }

        } catch (Error e) {}

        return result;
    }

    internal virtual int compare_by_property (MediaObject media_object,
                                              string      property) {
        switch (property) {
        case "@id":
            return this.compare_string_props (this.id, media_object.id);
        case "@parentID":
            return this.compare_string_props (this.parent.id,
                                              media_object.parent.id);
        case "dc:title":
            return this.compare_string_props (this.title, media_object.title);
        case "upnp:class":
            return this.compare_string_props (this.upnp_class,
                                              media_object.upnp_class);
        case "dc:artist":
            return this.compare_string_props (this.artist, media_object.artist);
        case "upnp:genre":
            return this.compare_string_props (this.genre, media_object.genre);
        case "dc:creator":
            return this.compare_string_props (this.creator,
                                              media_object.creator);
        case "dc:date":
            return this.compare_by_date (media_object);
        default:
            return 0;
        }
    }

    protected int compare_string_props (string prop1, string prop2) {
        if (prop1 == null) {
            return -1;
        } else if (prop2 == null) {
            return 1;
        } else {
            return prop1.collate (prop2);
        }
    }

    internal virtual DIDLLiteResource add_resource
                                        (DIDLLiteObject object,
                                         string?        uri,
                                         string         protocol,
                                         string?        import_uri = null)
                                         throws Error {
        var res = object.add_resource ();

        return res;
    }

    protected int compare_int_props (int prop1, int prop2) {
        return (prop1 - prop2).clamp (-1, 1);
    }

    private async bool check_writable (File file, Cancellable? cancellable)
                                       throws Error {
        // Special URI scheme to indicate that this is a writable container
        // but doesn't have any real filesystem backing
        if (WritableContainer.WRITABLE_SCHEME.has_prefix
                                        (file.get_uri_scheme())) {
            return true;
        }

        if (!file.is_native ()) {
            return false;
        }

        try {
            var info = yield file.query_info_async (
                    FileAttribute.ACCESS_CAN_WRITE,
                    FileQueryInfoFlags.NONE,
                    Priority.DEFAULT,
                    cancellable);

            return info.get_attribute_boolean (FileAttribute.ACCESS_CAN_WRITE);
        } catch (IOError.NOT_FOUND error) {
            return true;
        }
    }

    private int compare_by_date (MediaObject object) {
        if (this.date == null) {
            return -1;
        } else if (object.date == null) {
            return 1;
        } else {
            var our_date = this.date;
            var other_date = object.date;

            if (!our_date.contains ("T")) {
                our_date += "T00:00:00Z";
            }

            if (!other_date.contains ("T")) {
                other_date += "T00:00:00Z";
            }

            var tv1 = TimeVal ();
            assert (tv1.from_iso8601 (this.date));

            var tv2 = TimeVal ();
            assert (tv2.from_iso8601 (object.date));

            var ret = this.compare_long (tv1.tv_sec, tv2.tv_sec);
            if (ret == 0) {
                ret = this.compare_long (tv1.tv_usec, tv2.tv_usec);
            }

            return ret;
        }
    }

    private int compare_long (long a, long b) {
        if (a < b) {
            return -1;
        } else if (a > b) {
            return 1;
        } else {
            return 0;
        }
    }

    private string get_first (GLib.List<DIDLLiteContributor>? contributors) {
        if (contributors != null) {
            return contributors.data.name;
        }

        return "";
    }

    internal string get_protocol_for_uri (string uri) throws Error {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            throw new MediaItemError.BAD_URI (_("Bad URI: %s"), uri);
        }

        if (scheme == "http") {
            return "http-get";
        } else if (scheme == "file") {
            return "internal";
        } else if (scheme == "rtsp") {
            // FIXME: Assuming that RTSP is always accompanied with RTP over UDP
            return "rtsp-rtp-udp";
        } else {
            // Assume the protocol to be the scheme of the URI
            warning (_("Failed to probe protocol for URI %s. Assuming '%s'"),
                     uri,
                     scheme);

            return scheme;
        }
    }
}
