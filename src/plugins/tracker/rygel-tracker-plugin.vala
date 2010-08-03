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

using Gee;

public class Rygel.Tracker.Plugin : Rygel.MediaServerPlugin {
    // class-wide constants
    private const string ICON = BuildConfig.DATA_DIR + // Path
                                "/icons/hicolor/48x48/apps/tracker.png";

    public Plugin () {
        base ("Tracker",
              // @REALNAME@ is substituted for user's real name
              // and it doesn't need translation.
              _("@REALNAME@'s media"));

        var icon_info = new IconInfo ("image/png");

        try {
            icon_info.uri = Filename.to_uri (ICON, null);
            icon_info.width = 48;
            icon_info.height = 48;
            icon_info.depth = 24;

            this.add_icon (icon_info);
        } catch (ConvertError err) {
            warning (_("Error creating URI from %s: %s"), ICON, err.message);
        }
    }

    public override MediaContainer? get_root_container (GUPnP.Context context) {
        return new RootContainer (this.title);
    }
}

