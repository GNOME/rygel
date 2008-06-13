/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2007 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jorn Baayen <jorn@openedhand.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */
using GLib;
using GUPnP;

public class GUPnP.MediaServer: RootDevice {
    public static const string CONTENT_DIR =
                        "urn:schemas-upnp-org:service:ContentDirectory";
    public static const string MEDIA_RECEIVER_REGISTRAR =
                        "urn:microsoft.com:service:X_MS_MediaReceiverRegistrar";

    private ContentDirectory content_dir; /* ContentDirectory */
    private MediaReceiverRegistrar msr;  /* MS MediaReceiverRegistrar */

    construct {
        ResourceFactory factory = this.resource_factory;

        /* Register GUPnP.ContentDirectory */
        factory.register_resource_type (CONTENT_DIR + ":1",
                                        typeof (ContentDirectory));
        factory.register_resource_type (CONTENT_DIR + ":2",
                                        typeof (ContentDirectory));

        /* Register GUPnP.MediaReceiverRegistrar */
        factory.register_resource_type (MEDIA_RECEIVER_REGISTRAR + ":1",
                                        typeof (MediaReceiverRegistrar));
        factory.register_resource_type (MEDIA_RECEIVER_REGISTRAR + ":2",
                                        typeof (MediaReceiverRegistrar));

        /* Now create the sevice objects */
        this.content_dir = (ContentDirectory) this.get_service (CONTENT_DIR);
        this.msr = (MediaReceiverRegistrar) this.get_service
                                                (MEDIA_RECEIVER_REGISTRAR);
    }

    public MediaServer (GUPnP.Context context,
                        Xml.Doc       description_doc,
                        string        relative_location) {
        this.context = context;
        this.resource_factory = GUPnP.ResourceFactory.get_default ();
        this.root_device = null;
        this.description_doc = description_doc;
        this.relative_location = relative_location;
    }
}

