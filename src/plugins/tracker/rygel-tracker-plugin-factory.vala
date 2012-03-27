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
using Gee;

private Rygel.Tracker.PluginFactory plugin_factory;

public void module_init (PluginLoader loader) {
    if (loader.plugin_disabled (Rygel.Tracker.Plugin.NAME)) {
        message ("Plugin '%s' disabled by user, ignoring..",
                 Rygel.Tracker.Plugin.NAME);

        return;
    }

    try {
        plugin_factory = new Rygel.Tracker.PluginFactory (loader);
    } catch (Error err) {
        warning (_("Failed to start Tracker service: %s. Plugin disabled."),
                 err.message);
    }
}

public class Rygel.Tracker.PluginFactory {
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker1";
    private const string STATISTICS_OBJECT =
                                        "/org/freedesktop/Tracker1/Statistics";

    StatsIface stats;
    PluginLoader loader;

    public PluginFactory (PluginLoader loader) throws IOError, DBusError {
        this.stats = Bus.get_proxy_sync (BusType.SESSION,
                                         TRACKER_SERVICE,
                                         STATISTICS_OBJECT,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);
        this.loader = loader;

        this.stats.get ();

        this.loader.add_plugin (new Tracker.Plugin ());
    }
}

