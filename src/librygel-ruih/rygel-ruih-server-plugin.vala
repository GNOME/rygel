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

/**
 * This is the base class for every Rygel UPnP Ruih plugin.
 *
 * This class is useful when implementing Rygel Ruih Server plugins.
 *
 */
public class Rygel.RuihServerPlugin : Rygel.Plugin {
    private const string RUIH_SERVER_DESC_PATH = BuildConfig.DATA_DIR +
                                                 "/xml/RuihServer2.xml";
    private const string RUIH = "urn:schemas-upnp-org:device:RemoteUIServer";


    /**
     * Create an instance of the plugin.
     *
     * @param name The non-human-readable name for the plugin, used in UPnP
     * messages and in the Rygel configuration file.
     * @param title An optional human-readable name (friendlyName) of the UPnP
     * RUIH server provided by the plugin. If the title is empty then the name
     * will be used.
     * @param description An optional human-readable description
     * (modelDescription) of the UPnP RUIH server provided by the plugin.
     */
    public RuihServerPlugin (string  name,
                             string? title,
                             string? description = null,
                             PluginCapabilities capabilities =
                                        PluginCapabilities.NONE) {
        Object (desc_path : RUIH_SERVER_DESC_PATH,
                name : name,
                title : title,
                description : description,
                capabilities : capabilities);
    }

    public override void constructed () {
        base.constructed ();

        var resource = new ResourceInfo (RuihService.UPNP_ID,
                                         RuihService.UPNP_TYPE,
                                         RuihService.DESCRIPTION_PATH,
                                         typeof (RuihService));
        this.add_resource (resource);
    }
}
