/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009,2010 Nokia Corporation.
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
using DBus;
using Gee;

/**
 * Implementation of External ContentDirectory service.
 */
public class Rygel.ExternalContentDir : Rygel.ContentDirectory {
    // Pubic methods
    public override MediaContainer? create_root_container () {
        var plugin = (ExternalPlugin) this.root_device.resource_factory;

        Connection connection;

        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error err) {
            // By this time plugin should have successfully accessed the
            // the session bus, so this in theory can not fail.
            assert_not_reached ();
        }

        var actual_container = connection.get_object (plugin.service_name,
                                                      plugin.root_object)
                                                      as ExternalMediaContainer;

        return new ExternalContainer ("0",
                                      plugin.service_name,
                                      this.context.host_ip,
                                      actual_container);
    }
}

