/*
 * Copyright (C) 2009 Thijs Vermeir <thijsvermeir@gmail.com>
 *
 * Author: Thijs Vermeir <thijsvermeir@gmail.com>
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

using Rygel;
using Gee;

public void module_init (PluginLoader loader) {
    var plugin = new GstLaunch.Plugin ();

    loader.add_plugin (plugin);
}

public class Rygel.GstLaunch.Plugin : Rygel.MediaServerPlugin {
    public const string NAME = "GstLaunch";

    public Plugin () {
        var root_container = new RootContainer ("Gst Launch");

        base (root_container, Plugin.NAME);
    }

    public override void constructed () {
        base.constructed ();

        ((RootContainer) this.root_container).init ();
    }
}
