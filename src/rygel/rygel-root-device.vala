/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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
using CStuff;
using Gee;

/**
 * Represents a Root device.
 */
public class Rygel.RootDevice: GUPnP.RootDevice {
    internal ArrayList<ServiceInfo> services;   /* Services we implement */

    private Xml.Doc *desc_doc;

    public RootDevice (GUPnP.Context context,
                       Plugin        plugin,
                       Xml.Doc      *description_doc,
                       string        description_path,
                       string        description_dir) {
        this.resource_factory = plugin;
        this.root_device = null;
        this.context = context;

        this.description_doc = description_doc;
        this.description_path = description_path;
        this.description_dir = description_dir;

        this.desc_doc = description_doc;
        this.services = new ArrayList<ServiceInfo> ();

        // Now create the sevice objects
        foreach (ResourceInfo info in plugin.resource_infos) {
            // FIXME: We only support plugable services for now
            if (info.type.is_a (typeof (Service))) {
                var service = this.get_service (info.upnp_type);

                this.services.add (service);
            }
        }
    }

    ~RootDevice () {
        delete this.desc_doc;
    }
}

