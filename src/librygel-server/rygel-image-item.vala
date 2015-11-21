/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
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
 * Represents an image item.
 */
public class Rygel.ImageItem : MediaFileItem, VisualItem {
    public new const string UPNP_CLASS = "object.item.imageItem";

    //TODO: This property documentation is not used.
    //See valadoc bug: https://bugzilla.gnome.org/show_bug.cgi?id=684367

    /**
     * The width of the image in pixels.
     * A value of -1 means that the width is unknown and will not, or did not,
     * appear in DIDL-Lite XML.
     */
    public int width { get; set; default = -1; }

    /**
     * The height of the image in pixels.
     * A value of -1 means that the height is unknown and will not, or did not,
     * appear in DIDL-Lite XML.
     */
    public int height { get; set; default = -1; }

    /**
     *The number of bits per pixel used to represent the image resource.
     * A value of -1 means that the color depth is unknown and will not, or did
     * not, appear in DIDL-Lite XML.
     */
    public int color_depth { get; set; default = -1; }

    /**
     * Thumbnail pictures to represent the image.
     */
    public ArrayList<Thumbnail> thumbnails { get; protected set; }

    public ImageItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = ImageItem.UPNP_CLASS) {
        Object (id : id,
                parent : parent,
                title : title,
                upnp_class : upnp_class);
    }

    public override void constructed () {
        base.constructed ();

        this.thumbnails = new ArrayList<Thumbnail> ();
    }

    public override void add_uri (string uri) {
        base.add_uri (uri);

        this.add_thumbnail_for_uri (uri);
    }

    internal override MediaResource get_primary_resource () {
        var res = base.get_primary_resource ();

        this.set_visual_resource_properties (res);

        res.dlna_flags |= DLNAFlags.INTERACTIVE_TRANSFER_MODE;

        return res;
    }

    internal override void add_additional_resources (HTTPServer server) {
        base.add_additional_resources (server);

        this.add_thumbnail_resources (server);
    }

}
