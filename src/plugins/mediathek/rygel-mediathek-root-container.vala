/*
 * Copyright (C) 2009-2011 Jens Georg
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

public class Rygel.Mediathek.RootContainer : Rygel.TrackableContainer,
                                             Rygel.SimpleContainer {
    private Session session;
    private static RootContainer instance;
    private static int DEFAULT_UPDATE_INTERVAL = 1800;

    public static RootContainer get_instance () {
        if (RootContainer.instance == null) {
            RootContainer.instance = new RootContainer ();
            RootContainer.instance.init.begin ();
        }

        return instance;
    }

    public static Session get_default_session () {
        return get_instance ().session;
    }

    private RootContainer () {
        base.root ("ZDF Mediathek");
        this.session = new Soup.Session ();
    }

    private async void init () {
        Gee.ArrayList<int> feeds = null;
        int update_interval = DEFAULT_UPDATE_INTERVAL;

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

        try {
            update_interval = config.get_int ("ZDFMediathek",
                                              "update-interval",
                                              600,
                                              int.MAX);
        } catch (Error error) {
            update_interval = DEFAULT_UPDATE_INTERVAL;
        }

        foreach (int id in feeds) {
            yield this.add_child_tracked (new RssContainer (this, id));
        }

        Timeout.add_seconds (update_interval, () => {
            foreach (var child in this.children) {
                var container = child as RssContainer;

                container.update.begin ();
            }

            return true;
        });
    }

    public async void add_child (MediaObject object) {
        this.add_child_container (object as MediaContainer);
    }
}
