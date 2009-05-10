/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using GUPnP;
using GConf;
using CStuff;
using Gee;

public class Rygel.Main : Object {
    private PluginLoader plugin_loader;
    private MediaServerFactory ms_factory;
    private ArrayList<MediaServer> media_servers;

    private MainLoop main_loop;

    private int exit_code;

    public Main () throws GLib.Error {
        Environment.set_application_name (_(BuildConfig.PACKAGE_NAME));

        this.media_servers = new ArrayList<MediaServer> ();
        this.plugin_loader = new PluginLoader ();
        this.ms_factory = new MediaServerFactory ();
        this.main_loop = new GLib.MainLoop (null, false);

        this.exit_code = 0;

        this.plugin_loader.plugin_available += this.on_plugin_loaded;

        Utils.on_application_exit (this.application_exit_cb);
    }

    public int run () {
        this.plugin_loader.load_plugins ();

        this.main_loop.run ();

        return this.exit_code;
    }

    public void exit (int exit_code) {
        this.exit_code = exit_code;
        this.main_loop.quit ();
    }

    private void application_exit_cb () {
        this.exit (0);
    }

    private void on_plugin_loaded (PluginLoader plugin_loader,
                                   Plugin       plugin) {
        try {
            var server = this.ms_factory.create_media_server (plugin);

            server.available = plugin.available;

            media_servers.add (server);

            plugin.notify["available"] += this.on_plugin_notify;
        } catch (GLib.Error error) {
            warning ("Failed to create MediaServer for %s. Reason: %s\n",
                     plugin.name,
                     error.message);
        }
    }

    private void on_plugin_notify (Plugin    plugin,
                                   ParamSpec spec) {
        foreach (var server in this.media_servers) {
            if (server.resource_factory == plugin) {
                server.available = plugin.available;
            }
        }
    }

    public static int main (string[] args) {
        Main main;

        // initialize gstreamer
        Gst.init (ref args);

        try {
            main = new Main ();
        } catch (GLib.Error err) {
            error ("%s", err.message);

            return -1;
        }

        int exit_code = main.run ();

        return exit_code;
    }
}

