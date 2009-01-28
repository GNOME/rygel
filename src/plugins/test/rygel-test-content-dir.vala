/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Gst;
using Gee;

/**
 * Implementation of ContentDirectory service, meant for testing purposes only.
 */
public class Rygel.TestContentDir : ContentDirectory {
    private ArrayList<MediaItem> items;

    /* Pubic methods */
    public override void constructed () {
        // Chain-up to base first
        base.constructed ();

        this.http_server.need_stream_source += this.on_need_stream_source;

        this.items = new ArrayList<MediaItem> ();
        this.items.add (new TestAudioItem ("sinewave",
                                           this.root_container.id,
                                           "Sine Wave",
                                           this.http_server));
        this.items.add (new TestVideoItem ("smtpe",
                                           this.root_container.id,
                                           "SMTPE",
                                           this.http_server));

        // Now we know how many top-level items we have
        this.root_container.child_count = this.items.size;
    }

    public override ArrayList<MediaObject> get_root_children (
                                                 uint     offset,
                                                 uint     max_count,
                                                 out uint child_count)
                                                 throws GLib.Error {
        child_count = this.items.size;

        Gee.List<MediaObject> children = null;

        if (max_count == 0 && offset == 0) {
            children = this.items;
        } else {
            uint stop = offset + max_count;

            stop = stop.clamp (0, child_count);
            children = this.items.slice ((int) offset, (int) stop);
        }

        if (children == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return (ArrayList<MediaObject>) children;
    }

    public override MediaObject find_object_by_id (string object_id)
                                                   throws GLib.Error {
        MediaItem item = null;

        foreach (MediaItem tmp in this.items) {
            if (object_id == tmp.id) {
                item = tmp;

                break;
            }
        }

        if (item == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return item;
    }

    /* Private methods */
    private void on_need_stream_source (HTTPServer  http_server,
                                        MediaItem   item,
                                        out Element src) {
        try {
            src = ((TestItem) item).create_gst_source ();
        } catch (Error error) {
            critical ("Error creating Gst source element for item %s: %s",
                      item.id,
                      error.message);

            return;
        }
    }
}

