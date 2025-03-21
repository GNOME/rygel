/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Gee;
using Tsparql;

public class Rygel.LocalSearch.Plugin : Rygel.MediaServerPlugin {
    public const string NAME = "LocalSearch";

    private static RootContainer root;

    public Plugin () throws Error {
        if (root == null) {
            // translators: @REALNAME@ is substituted for user's real name and it doesn't need translation.
            root = new RootContainer (_("@REALNAME@’s media"));
        }

        base (root, Plugin.NAME, null, PluginCapabilities.NONE);
    }
}
