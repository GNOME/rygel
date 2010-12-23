/*
 * Copyright (C) 2008-2009 Jens Georg <mail@jensge.org>.
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

private const string TRACKER_PLUGIN = "Tracker";
private const string OUR_PLUGIN = "MediaExport";

/**
 * Simple plugin which exposes the media contents of a directory via UPnP.
 *
 */
public void module_init (PluginLoader loader) {
    var plugin = new MediaExport.Plugin ();

    Idle.add (() => {
       foreach (var loaded_plugin in loader.list_plugins ()) {
            on_plugin_available (loaded_plugin, plugin);
       }

       loader.plugin_available.connect ((new_plugin) => {
           on_plugin_available (new_plugin, plugin);
       });

       return false;
    });

    loader.add_plugin (plugin);
}

public void on_plugin_available (Plugin plugin, Plugin our_plugin) {
    if (plugin.name == TRACKER_PLUGIN &&
        our_plugin.available == plugin.available) {
        if (plugin.available) {
            message ("Disabling plugin '%s' in favor of plugin '%s'",
                     OUR_PLUGIN,
                     TRACKER_PLUGIN);
            try {
                var config = MetaConfig.get_default ();
                var enabled = config.get_bool ("MediaExport", "enabled");
                if (enabled) {
                    var root = Rygel.MediaExport.RootContainer.get_instance ()
                        as Rygel.MediaExport.RootContainer;

                    root.shutdown ();
                }
            } catch (Error error) {};
        } else {
            message ("Plugin '%s' disabled, enabling '%s' plugin",
                     TRACKER_PLUGIN,
                     OUR_PLUGIN);
        }

        our_plugin.available = !plugin.available;
    }
}

public class Rygel.MediaExport.Plugin : Rygel.MediaServerPlugin {
    public Plugin () {
        base (OUR_PLUGIN, _("@REALNAME@'s media"));
    }

    public override MediaContainer get_root_container () {
        try {
            return RootContainer.get_instance ();
        } catch (Error error) {
            warning ("Could not create root container: %s. " +
                     "Disabling plugin",
                     error.message);
            this.available = false;
        }

        return new NullContainer ();
    }
}
