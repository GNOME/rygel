/*
 * Copyright (C) 2008-2009 Jens Georg <mail@jensge.org>.
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

using Rygel;
using GUPnP;
using Gee;
using GLib;

/**
 * Simple plugin which exposes the media contents of a directory via UPnP.
 * 
 * This plugin is currently meant for testing purposes only. It has several 
 * drawbacks like:
 *
 * * No sorting
 * * flat hierarchy
 * * no metadata extraction apart from content type
 * * no monitoring
 */
[ModuleInit]
public void module_init (PluginLoader loader) {
    Plugin plugin = new Plugin ("Folder", "@REALNAME@'s media");

    var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                          ContentDirectory.UPNP_TYPE,
                                          ContentDirectory.DESCRIPTION_PATH,
                                          typeof (Rygel.FolderContentDir));

    plugin.add_resource (resource_info);

    loader.add_plugin (plugin);
}

public class Rygel.FolderContentDir : ContentDirectory {
    public override MediaContainer? create_root_container () {
        return new FolderRootContainer ();
    }
}
