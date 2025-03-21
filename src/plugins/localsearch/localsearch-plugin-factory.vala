/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009-2012 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

private Rygel.LocalSearch.PluginFactory plugin_factory;

public void module_init (PluginLoader loader) {
    try {
        plugin_factory = new Rygel.LocalSearch.PluginFactory (loader);
    } catch (Error err) {
        warning (_("Failed to start LocalSearch service: %s. Plugin disabled."),
                 err.message);
    }
}

public class Rygel.LocalSearch.PluginFactory {
    PluginLoader loader;

    public PluginFactory (PluginLoader loader) throws Error {
        this.loader = loader;

        this.loader.add_plugin (new LocalSearch.Plugin ());
    }
}
