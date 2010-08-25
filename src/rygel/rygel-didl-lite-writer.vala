/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

internal errordomain Rygel.DIDLLiteWriterError {
    UNSUPPORTED_OBJECT
}

/**
 * Responsible for serializing media objects.
 */
internal class Rygel.DIDLLiteWriter : GUPnP.DIDLLiteWriter {
    public Rygel.HTTPServer http_server;

    public DIDLLiteWriter (HTTPServer http_server) {
        this.http_server = http_server;
    }

    public void serialize (MediaObject media_object) throws Error {
        if (media_object is MediaItem) {
            ((MediaItem) media_object).serialize (this);
        } else if (media_object is MediaContainer) {
            this.serialize_container ((MediaContainer) media_object);
        } else {
            throw new DIDLLiteWriterError.UNSUPPORTED_OBJECT (
                _("Unable to serialize unsupported object"));
        }
    }

    private void serialize_container (MediaContainer container) throws Error {
        var didl_container = this.add_container ();
        if (container.parent != null) {
            didl_container.parent_id = container.parent.id;
        } else {
            didl_container.parent_id = "-1";
        }

        didl_container.id = container.id;
        didl_container.title = container.title;
        didl_container.child_count = container.child_count;
        didl_container.upnp_class = container.upnp_class;
        didl_container.restricted = container.uris.size <= 0;
        didl_container.searchable = true;

        if (!didl_container.restricted) {
            weak Xml.Node node = (Xml.Node) didl_container.xml_node;
            weak Xml.Ns ns = (Xml.Ns) didl_container.upnp_namespace;

            foreach (var create_class in container.create_classes) {
                node.new_child (ns, "createClass", create_class);
            }
        }
    }
}
