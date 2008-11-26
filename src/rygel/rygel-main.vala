/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using GUPnP;
using GConf;
using CStuff;

public class Rygel.Main : Object {
    private PluginLoader plugin_loader;
    private MediaServerFactory ms_factory;
    private List<MediaServer> media_servers;

    public Main () throws GLib.Error {
        this.media_servers = new List<MediaServer> ();
        this.plugin_loader = new PluginLoader ();
        this.ms_factory = new MediaServerFactory ();

        this.plugin_loader.plugin_available += this.on_plugin_loaded;
    }

    public void run () {
        this.plugin_loader.load_plugins ();

        var main_loop = new GLib.MainLoop (null, false);
        main_loop.run ();
    }

    private void on_plugin_loaded (PluginLoader plugin_loader,
                                   Plugin       plugin) {
        try {
            var server = this.ms_factory.create_media_server (plugin);

            /* Make our device available */
            server.available = true;

            media_servers.append (server);
        } catch (GLib.Error error) {
            warning ("Failed to create MediaServer for %s. Reason: %s\n",
                     plugin.name,
                     error.message);
        }
    }

    public static int main (string[] args) {
        Main main;

        try {
            main = new Main ();
        } catch (GLib.Error err) {
            error ("%s", err.message);

            return -1;
        }

        main.run ();

        return 0;
    }
}

