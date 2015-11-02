/*
 * Copyright (C) 2013  Cable Television Laboratories, Inc.
 *
 * Author: Neha Shanbhag <N.Shanbhag@cablelabs.com>
 * Contact: http://www.cablelabs.com/
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

internal class Plugin : Rygel.RuihServerPlugin {
    public Plugin (Rygel.PluginCapabilities capabilities) {
        base ("LibRygelRuih", "LibRygelRuih", null, capabilities);
    }
}

/**
 * This class may be used to implement in-process UPnP RUIH servers.
 *
 * Call rygel_media_device_add_interface () on the RygelRuihServer to allow it
 * to serve requests via that network interface.
 *
 */
public class Rygel.RuihServer : MediaDevice {

    /**
     * Create a RuihServer to serve the UIs.
     */
    public RuihServer (string title,
                       PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        Object (title: title,
                capabilities: capabilities);
    }

    public override void constructed () {
        base.constructed ();

        if (this.plugin == null) {
            this.plugin = new global::Plugin (this.capabilities);
        }
        this.plugin.title = this.title;
    }
}
