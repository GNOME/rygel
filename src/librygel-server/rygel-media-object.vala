/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * The derived RygelMediaContainer class represents a container,
 * and the derived RygelMediaItem classes (RygelAudioItem,
 * RygelImageItem and RygelVideoItem) represent media items.
 *
 * These objects correspond to items and containers in the UPnP ContentDirectory's DIDL-Lite XML.
 */
public abstract class Rygel.MediaObject : GLib.Object {
    private static Regex real_name_regex;
    private static Regex user_name_regex;
    private static Regex host_name_regex;

    public string id;
    public string ref_id;
    public string upnp_class;
    public uint64 modified;
    public uint object_update_id;
    public Gee.ArrayList<string> uris;

    // You can keep both a unowned and owned ref to parent of this MediaObject.
    // In most cases, one will only need to keep an unowned ref to avoid cyclic
    // references since usually parent container will keep refs to child items.
    // However in some cases, one only wants the parent to exist as long as the
    // child exists and it is in those cases, you will want to use 'parent_ref'.
    //
    // You must set 'parent' if you set 'parent_ref' but the opposite is not
    // mandatory.
    public unowned MediaContainer parent;
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
    public string title {
        get {
            return _title;
        }

        set {
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
            } catch (GLib.RegexError err) {
                assert_not_reached ();
            }
        }
    }

    internal abstract OCMFlags ocm_flags { get; }

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
        } catch (GLib.RegexError err) {
            assert_not_reached ();
        }
    }

    construct {
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

    internal abstract DIDLLiteObject serialize (DIDLLiteWriter writer,
                                                HTTPServer     http_server)
                                                throws Error;

    internal virtual void apply_didl_lite (DIDLLiteObject didl_object) {
        this.title = didl_object.title;
    }

    internal async DIDLLiteFragmentResult apply_fragments
                                        (LinkedList<string> current_fragments,
                                         LinkedList<string> new_fragments,
                                         HTTPServer         http_server) {
        var result = DIDLLiteFragmentResult.UNKNOWN_ERROR;

        try {
            var writer = new DIDLLiteWriter (null);
            var didl_object = this.serialize (writer, http_server);

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

    protected int compare_int_props (int prop1, int prop2) {
        return (prop1 - prop2).clamp (-1, 1);
    }

    private async bool check_writable (File file, Cancellable? cancellable)
                                       throws Error {
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
}
