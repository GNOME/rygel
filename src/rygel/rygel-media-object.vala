/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
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
 * Represents a media object (container and item).
 */
public abstract class Rygel.MediaObject : GLib.Object {
    public string id;
    public string upnp_class;
    public uint64 modified;
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
            this._title = value.replace ("@REALNAME@",
                                         Environment.get_real_name ());
            _title = _title.replace ("@USERNAME@",
                                     Environment.get_user_name ());
            _title = _title.replace ("@HOSTNAME@",
                                     Environment.get_host_name ());
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

            var info = yield file.query_info_async (
                                        FILE_ATTRIBUTE_ACCESS_CAN_WRITE,
                                        FileQueryInfoFlags.NONE,
                                        Priority.DEFAULT,
                                        cancellable);
            if (info.get_attribute_boolean (FILE_ATTRIBUTE_ACCESS_CAN_WRITE)) {
                return file;
            }
        }

        return null;
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
}
