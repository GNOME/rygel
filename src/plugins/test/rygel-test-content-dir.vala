/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel;
using GUPnP;
using DBus;

/**
 * Implementation of ContentDirectory service, meant for testing purposes only.
 */
public class Rygel.TestContentDir : ContentDirectory {
    private List<MediaItem> items;

    /* Pubic methods */
    public override void constructed () {
        // Chain-up to base first
        base.constructed ();

        Streamer streamer = new Streamer (context, "RygelTest");

        this.items = new List<MediaItem> ();
        this.items.append (new TestAudioItem ("sinewave",
                                              this.root_container.id,
                                              "Sine Wave",
                                              streamer));

        // Now we know how many top-level items we have
        this.root_container.child_count = this.items.length ();
    }

    public override void add_metadata (DIDLLiteWriter didl_writer,
                                       BrowseArgs     args) throws GLib.Error {
        MediaItem item = find_item_by_id (args.object_id);
        if (item == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        item.serialize (didl_writer);
        args.update_id = uint32.MAX;
    }

    public override void add_root_children_metadata (DIDLLiteWriter didl_writer,
                                                     BrowseArgs     args)
                                                     throws GLib.Error {
        foreach (MediaItem item in this.items)
            item.serialize (didl_writer);

        args.total_matches = args.number_returned = this.items.length ();
        args.update_id = uint32.MAX;
    }

    /* Private methods */
    private MediaItem? find_item_by_id (string item_id) {
        MediaItem item = null;

        foreach (MediaItem tmp in this.items) {
            if (item_id == tmp.id) {
                item = tmp;

                break;
            }
        }

        return item;
    }
}

