/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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

using Rygel;
using Gee;
using CStuff;

[ModuleInit]
public void module_init (PluginLoader loader) {
    string MEDIA_RENDERER_DESC_PATH = BuildConfig.DATA_DIR +
                                      "/xml/MediaRenderer2.xml";

    var plugin = new Plugin (MEDIA_RENDERER_DESC_PATH,
                             "GstRenderer",
                             _("GStreamer Renderer"));

    plugin.add_resource (new ResourceInfo (ConnectionManager.UPNP_ID,
                                           ConnectionManager.UPNP_TYPE,
                                           ConnectionManager.DESCRIPTION_PATH,
                                           typeof (GstConnectionManager)));
    plugin.add_resource (new ResourceInfo (GstAVTransport.UPNP_ID,
                                           GstAVTransport.UPNP_TYPE,
                                           GstAVTransport.DESCRIPTION_PATH,
                                           typeof (GstAVTransport)));
    plugin.add_resource (new ResourceInfo (GstRenderingControl.UPNP_ID,
                                           GstRenderingControl.UPNP_TYPE,
                                           GstRenderingControl.DESCRIPTION_PATH,
                                           typeof (GstRenderingControl)));

    loader.add_plugin (plugin);
}

