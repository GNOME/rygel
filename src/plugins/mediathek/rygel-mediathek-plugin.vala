/*
 * Copyright (C) 2009 Jens Georg
 *
 * Author: Jens Georg <mail@jensge.org>
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
using GUPnP;

// remove when bgo#639700 is fixed and "delete" resolves to the free_func and
// not to g_free
[CCode (cname = "xmlXPathFreeObject")]
internal extern void xpath_free_object (Xml.XPath.Object *object);

public void module_init (PluginLoader loader) {
    var plugin = new Mediathek.Plugin ();

    loader.add_plugin (plugin);
}

public class Rygel.Mediathek.Plugin : Rygel.MediaServerPlugin {
    public const string NAME = "ZDFMediathek";

    public Plugin () {
        base (RootContainer.get_instance (),
              Plugin.NAME,
              null,
              PluginCapabilities.TRACK_CHANGES);
    }
}
