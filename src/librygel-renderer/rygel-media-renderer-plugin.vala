/*
 * Copyright (C) 2008,2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
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

/**
 * This is the base class for every Rygel UPnP renderer plugin.
 *
 * This class is useful when implementing Rygel renderer plugins.
 *
 * Renderer plugins should also implement their own #RygelMediaPlayer
 * and return an instance of it from their get_player() implementation.
 */
public class Rygel.MediaRendererPlugin : Rygel.Plugin {
    private static const string MEDIA_RENDERER_DESC_PATH =
                                BuildConfig.DATA_DIR +
                                "/xml/MediaRenderer2.xml";

    /**
     * Create an instance of the plugin.
     *
     * @param name The non-human-readable name for the plugin and its renderer, used in UPnP messages and in the Rygel configuration file.
     * @param title An optional human-readable name (friendlyName) of the UPnP renderer provided by the plugin. If the title is empty then the name will be used.
     * @param description An optional human-readable description (modelDescription) of the UPnP renderer provided by the plugin.
     */
    public MediaRendererPlugin (string  name,
                                string? title,
                                string? description = null,
                                PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        base (MEDIA_RENDERER_DESC_PATH, name, title, description, capabilities);

        var resource = new ResourceInfo (ConnectionManager.UPNP_ID,
                                         ConnectionManager.UPNP_TYPE,
                                         ConnectionManager.DESCRIPTION_PATH,
                                         typeof (SinkConnectionManager));
        this.add_resource (resource);

        resource = new ResourceInfo (AVTransport.UPNP_ID,
                                     AVTransport.UPNP_TYPE,
                                     AVTransport.DESCRIPTION_PATH,
                                     typeof (AVTransport));
        this.add_resource (resource);

        resource = new ResourceInfo (RenderingControl.UPNP_ID,
                                     RenderingControl.UPNP_TYPE,
                                     RenderingControl.DESCRIPTION_PATH,
                                     typeof (RenderingControl));
        this.add_resource (resource);
    }

    public virtual MediaPlayer? get_player () {
        return null;
    }
}
