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

public class Rygel.MediathekRootContainer : Rygel.SimpleContainer {
    internal SessionAsync session;
    private static MediathekRootContainer instance;

    private bool on_schedule_update () {
        message("Scheduling update for all feeds....");
        foreach (var container in this.children) {
            ((MediathekRssContainer) container).update ();
        }

        return true;
    }

    public static MediathekRootContainer get_instance () {
        if (MediathekRootContainer.instance == null) {
            MediathekRootContainer.instance = new MediathekRootContainer ();
        }

        return instance;
    }

    private MediathekRootContainer () {
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
            message ("Could not get RSS items from GConf, using defaults");
            feeds.add (508);
        }

        foreach (int id in feeds) {
            this.children.add (new MediathekRssContainer (this, id));
        }

        this.child_count = this.children.size;
        GLib.Timeout.add_seconds (1800, on_schedule_update);
    }
}
