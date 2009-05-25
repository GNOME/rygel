/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

public class TrackerPlugin : Plugin {
    // class-wide constants
    private const string ICON = BuildConfig.DATA_DIR + // Path
                                "/icons/hicolor/48x48/apps/tracker.png";

    public TrackerPlugin () {
        base ("Tracker", "@REALNAME@'s media");

        // We only implement a ContentDirectory service
        var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                              ContentDirectory.UPNP_TYPE,
                                              ContentDirectory.DESCRIPTION_PATH,
                                              typeof (MediaTracker));

        this.add_resource (resource_info);

        var icon_info = new IconInfo ("image/png", // Mimetype
                                      48,          // width
                                      48,          // height
                                      24,          // depth
                                      ICON);       // Icon Path

        this.add_icon (icon_info);
    }
}

