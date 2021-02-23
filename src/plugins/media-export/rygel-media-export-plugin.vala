/*
 * Copyright (C) 2008-2009 Jens Georg <mail@jensge.org>.
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
using GUPnP;

private const string TRACKER_PLUGIN = "Tracker";
private const string TRACKER3_PLUGIN = "Tracker3";

/**
 * Simple plugin which exposes the media contents of a directory via UPnP.
 *
 */
public void module_init (PluginLoader loader) {
    try {
        // Instantiate the plugin object (it may fail if loading
        // database did not succeed):
        var plugin = new MediaExport.Plugin ();

        // Check what other plugins are loaded,
        // and check when other plugins are loaded later:
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
    } catch (Error error) {
        warning (_("Failed to load plugin %s: %s"),
                 MediaExport.Plugin.NAME,
                 error.message);
    }
}

public void on_plugin_available (Plugin plugin, Plugin our_plugin) {
    // Do not allow this plugin and the tracker plugin to both be
    // active at the same time,
    // because they serve the same purpose.
    if (plugin.name == TRACKER_PLUGIN || plugin.name == TRACKER3_PLUGIN ) {
        if (our_plugin.active && !plugin.active) {
            // The Tracker plugin might be activated later,
            // so shut this plugin down if that happens.
            plugin.notify["active"].connect (() => {
                if (plugin.active) {
                    shutdown_media_export ();
                    our_plugin.active = !plugin.active;
                }
            });
        } else if (our_plugin.active == plugin.active) {
            if (plugin.active) {
                // The Tracker plugin is already active,
                // so shut this plugin down immediately.
                shutdown_media_export ();
            } else {
                // Log that we are starting this plugin
                // because the Tracker plugin is not active instead.
                message ("Plugin '%s' inactivate, activating '%s' plugin",
                         plugin.name,
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
            var root = Rygel.MediaExport.RootContainer.get_instance ();

            root.shutdown ();
        }
    } catch (Error error) {};
}

public class Rygel.MediaExport.Plugin : Rygel.MediaServerPlugin {
    public const string NAME = "MediaExport";

    /**
     * Instantiate the plugin.
     */
    public Plugin () throws Error {
        // Ensure that root container could be created and thus
        // database could be opened:
        RootContainer.ensure_exists ();
        // Call the base constructor,
        // passing the instance of our root container.
        base (RootContainer.get_instance (),
              NAME,
              null,
              PluginCapabilities.UPLOAD |
              PluginCapabilities.TRACK_CHANGES);
    }
}
