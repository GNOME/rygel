/*
 * Copyright (C) 2008 Nokia Corporation.
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

using Gee;
using GUPnP;
using CStuff;

/**
 * Represents a Rygel plugin. Plugins are supposed to provide an object of this
 * class or a subclass.
 */
public class Rygel.Plugin : GUPnP.ResourceFactory {
    private static const string MEDIA_SERVER_DESC_PATH =
                                BuildConfig.DATA_DIR + "/xml/MediaServer2.xml";

    public string name;
    public string title;
    public string description;

    // Path to description document
    public string desc_path;

    public bool available { get; set; }

    public ArrayList<ResourceInfo> resource_infos;
    public ArrayList<IconInfo> icon_infos;

    public Plugin (string  desc_path,
                   string  name,
                   string? title,
                   string? description = null) {
        this.desc_path = desc_path;
        this.name = name;
        this.title = title;
        this.description = description;

        this.available = true;

        if (title == null) {
            this.title = name;
        }

        this.resource_infos = new ArrayList<ResourceInfo> ();
        this.icon_infos = new ArrayList<IconInfo> ();
    }

    public Plugin.MediaServer (string  name,
                               string? title,
                               Type    content_dir_type,
                               string? description = null) {
        this (MEDIA_SERVER_DESC_PATH, name, title, description);

        // MediaServer implementations must implement ContentDirectory service
        var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                              ContentDirectory.UPNP_TYPE,
                                              ContentDirectory.DESCRIPTION_PATH,
                                              content_dir_type);
        this.add_resource (resource_info);

        // Register Rygel.ConnectionManager
        resource_info = new ResourceInfo (ConnectionManager.UPNP_ID,
                                          ConnectionManager.UPNP_TYPE,
                                          ConnectionManager.DESCRIPTION_PATH,
                                          typeof (SourceConnectionManager));

        this.add_resource (resource_info);
        resource_info = new ResourceInfo (
                                        MediaReceiverRegistrar.UPNP_ID,
                                        MediaReceiverRegistrar.UPNP_TYPE,
                                        MediaReceiverRegistrar.DESCRIPTION_PATH,
                                        typeof (MediaReceiverRegistrar));
        this.add_resource (resource_info);
    }

    public void add_resource (ResourceInfo resource_info) {
        this.resource_infos.add (resource_info);
        this.register_resource_type (resource_info.upnp_type,
                                     resource_info.type);
    }

    public void add_icon (IconInfo icon_info) {
        this.icon_infos.add (icon_info);
    }
}

