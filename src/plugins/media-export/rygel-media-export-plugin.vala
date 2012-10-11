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

/**
 * Simple plugin which exposes the media contents of a directory via UPnP.
 *
 */
public void module_init (PluginLoader loader) {
    if (loader.plugin_disabled (MediaExport.Plugin.NAME)) {
        message ("Plugin '%s' disabled by user, ignoring..",
                 MediaExport.Plugin.NAME);

        return;
    }

    MediaExport.Plugin plugin;

    try {
        plugin = new MediaExport.Plugin ();
    } catch (Error error) {
        warning ("Failed to initialize plugin '%s': %s. Ignoring..",
                 MediaExport.Plugin.NAME,
                 error.message);

        return;
    }

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
    if (plugin.name == TRACKER_PLUGIN) {
        if (our_plugin.active && !plugin.active) {
            // Tracker plugin might be activated later
            plugin.notify["active"].connect (() => {
                if (plugin.active) {
                    shutdown_media_export ();
                    our_plugin.active = !plugin.active;
                }
            });
        } else if (our_plugin.active == plugin.active) {
            if (plugin.active) {
                shutdown_media_export ();
            } else {
                message ("Plugin '%s' inactivate, activating '%s' plugin",
                         TRACKER_PLUGIN,
                         MediaExport.Plugin.NAME);
            }
            our_plugin.active = !plugin.active;
        }
    }
}

private void shutdown_media_export () {
    message ("Deactivating plugin '%s' in favor of plugin '%s'",
             MediaExport.Plugin.NAME,
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
}

public class Rygel.MediaExport.Plugin : Rygel.MediaServerPlugin {
    public const string NAME = "MediaExport";

    public Plugin () throws Error {
        base (RootContainer.get_instance (),
              NAME,
              null,
              PluginCapabilities.UPLOAD);
    }
}
