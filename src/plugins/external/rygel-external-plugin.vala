/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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

public class Rygel.ExternalPlugin : Rygel.Plugin {
    public string service_name;
    public string root_object;

    public ExternalPlugin (DBus.Connection connection,
                           string          service_name) {
        // org.gnome.UPnP.MediaServer1.NAME => /org/gnome/UPnP/MediaServer1/NAME
        var root_object = "/" + service_name.replace (".", "/");

        // Create proxy to MediaObject iface to get the display name through
        var obj = (ExternalMediaObject) connection.get_object (service_name,
                                                               root_object);
        base.MediaServer (service_name,
                          obj.display_name,
                          typeof (ExternalContentDir));

        this.service_name = service_name;
        this.root_object = root_object;
    }
}
