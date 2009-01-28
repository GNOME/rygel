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
using Gee;
using Gst;

/**
 * Represents the root container for Test media content hierarchy.
 */
public class Rygel.TestRootContainer : MediaContainer {
    private ArrayList<MediaItem> items;

    private HTTPServer http_server;

    public TestRootContainer (string     title,
                             HTTPServer http_server) {
        base.root (title, 0);

        this.http_server = http_server;
        this.http_server.need_stream_source += this.on_need_stream_source;

        this.items = new ArrayList<MediaItem> ();
        this.items.add (new TestAudioItem ("sinewave",
                                           this.id,
                                           "Sine Wave",
                                           this.http_server));
        this.items.add (new TestVideoItem ("smtpe",
                                           this.id,
                                           "SMTPE",
                                           this.http_server));

        // Now we know how many top-level items we have
        this.child_count = this.items.size;
    }

    public override Gee.List<MediaObject>? get_children (uint offset,
                                                         uint max_count)
                                                         throws GLib.Error {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        return this.items.slice ((int) offset, (int) stop);
    }

    public override MediaObject? find_object_by_id (string id)
                                                    throws GLib.Error {
        MediaItem item = null;

        foreach (MediaItem tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;

                break;
            }
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

