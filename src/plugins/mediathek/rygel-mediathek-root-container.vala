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

using Gee;
using Soup;

public class Rygel.Mediathek.RootContainer : Rygel.SimpleContainer {
    internal SessionAsync session;
    private static RootContainer instance;

    private bool on_schedule_update () {
        message("Scheduling update for all feeds....");
        foreach (var container in this.children) {
            ((RssContainer) container).update ();
        }

        return true;
    }

    public static RootContainer get_instance () {
        if (RootContainer.instance == null) {
            RootContainer.instance = new RootContainer ();
        }

        return instance;
    }

    private RootContainer () {
        base.root ("ZDF Mediathek");
        this.session = new Soup.SessionAsync ();
        Gee.ArrayList<int> feeds = null;

        var config = Rygel.MetaConfig.get_default ();
        try {
            feeds = config.get_int_list ("ZDFMediathek", "rss");
        } catch (Error error) {
            feeds = new Gee.ArrayList<int> ();
        }

        if (feeds.size == 0) {
            message ("Could not get RSS from configuration, using defaults");
            feeds.add (508);
        }

        foreach (int id in feeds) {
            this.add_child (new RssContainer (this, id));
        }

        GLib.Timeout.add_seconds (1800, on_schedule_update);
    }
}
