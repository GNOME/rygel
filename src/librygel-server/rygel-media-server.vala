/*
 * Copyright (C) 2012 Openismus GmbH.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

internal class Plugin : Rygel.MediaServerPlugin {
    public Plugin (Rygel.MediaContainer root_container,
                   Rygel.PluginCapabilities capabilities) {
        base (root_container, "LibRygelServer", null, capabilities);
    }
}

/**
 * This class may be used to implement in-process UPnP-AV media servers.
 *
 * Call rygel_media_device_add_interface() on the RygelMediaServer to allow it
 * to serve media via that network interface.
 *
 * See the
 * <link linkend="implementing-servers">Implementing Servers</link> section.
 */
public class Rygel.MediaServer : MediaDevice {
    public unowned MediaContainer root_container { construct; private get; }

    /**
     * Create a MediaServer to serve the media in the RygelMediaContainer.
     * For instance, you might use a RygelSimpleContainer. Alternatively,
     * you might use your own RygelMediaContainer implementation.
     *
     * Assuming that the RygelMediaContainer is correctly implemented,
     * the RygelMediaServer will respond appropriately to changes in the
     * RygelMediaContainer. 
     */
    public MediaServer (string title,
                        MediaContainer root_container,
                        PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        Object (title: title,
                root_container : root_container,
                capabilities: capabilities);
    }

    public override void constructed () {
        base.constructed ();

        if (this.plugin == null) {
            this.plugin = new global::Plugin (this.root_container,
                                              this.capabilities);
        }
        this.plugin.title = this.title;
    }
}
