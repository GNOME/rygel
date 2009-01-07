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
using Gst;

/**
 * Represents Test item.
 */
public abstract class Rygel.TestItem : Rygel.MediaItem {
    const string TEST_AUTHOR = "Zeeshan Ali (Khattak)";

    public string path;

    public TestItem (string   id,
                     string   parent_id,
                     string   title,
                     string   mime,
                     string   upnp_class,
                     Streamer streamer,
                     string   path) {
        base (id, parent_id, title, upnp_class, streamer);

        this.res.mime_type = mime;
        this.author = TEST_AUTHOR;
        this.path= path;

        // This is a live media
        this.live = true;

        this.res.uri = streamer.create_uri_for_path (path);

        streamer.stream_available += this.on_stream_available;
    }

    private void on_stream_available (Streamer streamer,
                                      Stream   stream,
                                      string   path) {
        if (path != this.path) {
            /* Not our path and therefore not interesting. */
            return;
        }

        // FIXME: This should be done by GstStream
        stream.set_mime_type (this.res.mime_type);

        try {
            Element src = this.create_gst_source ();
            // Ask streamer to handle the stream for us but use our source in
            // the pipeline.
            streamer.stream_from_gst_source (src, stream);
        } catch (Error error) {
            critical ("Error in attempting to start streaming %s: %s",
                      path,
                      error.message);

            return;
        }
    }

    protected abstract Element create_gst_source () throws Error;
}

