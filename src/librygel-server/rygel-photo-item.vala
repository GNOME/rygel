/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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
 * Represents a photo item.
 */
public class Rygel.PhotoItem : ImageItem {
    public new const string UPNP_CLASS = "object.item.imageItem.photo";

    public PhotoItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = PhotoItem.UPNP_CLASS) {
        Object (id : id,
                parent : parent,
                title : title,
                upnp_class : upnp_class);
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        if (!(media_object is PhotoItem)) {
           return 1;
        }

        var item = media_object as PhotoItem;

        switch (property) {
        default:
            return base.compare_by_property (item, property);
        }
    }

    private string get_first (GLib.List<DIDLLiteContributor>? contributors) {
        if (contributors != null) {
            return contributors.data.name;
        }

        return "";
    }

    internal override void apply_didl_lite (DIDLLiteObject didl_object) {
        base.apply_didl_lite (didl_object);

        this.creator = get_first (didl_object.get_creators ());
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                HTTPServer  http_server)
                                                throws Error {
        var didl_item = base.serialize (serializer, http_server);

        return didl_item;
    }
}
