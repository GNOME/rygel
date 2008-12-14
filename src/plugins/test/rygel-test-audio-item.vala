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
using Gee;
using Gst;

/**
 * Represents Test audio item.
 */
public class Rygel.TestAudioItem : Rygel.MediaItem {
    const string TEST_PATH = "/test.wav";
    const string TEST_MIMETYPE = "audio/x-wav";
    const string TEST_AUTHOR = "Zeeshan Ali (Khattak)";

    private Streamer streamer;

    public TestAudioItem (string   id,
                          string   parent_id,
                          string   title,
                          Streamer streamer) {
        base (id, parent_id, title, MediaItem.AUDIO_CLASS);
        this.mime = TEST_MIMETYPE;
        this.author = TEST_AUTHOR;
        this.uri = streamer.create_uri_for_path (TEST_PATH);

        this.streamer = streamer;

        streamer.stream_available += this.on_stream_available;
    }

    private void on_stream_available (Streamer streamer,
                                      Stream   stream,
                                      string   path) {
        if (path != TEST_PATH) {
            /* Not our path and therefore not interesting. */
            stream.reject ();
            return;
        }

        // FIXME: This should be done by GstStream
        stream.set_mime_type (TestAudioItem.TEST_MIMETYPE);

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

    private Element create_gst_source () throws Error {
        Bin bin = new Bin (this.title);

        dynamic Element src = ElementFactory.make ("audiotestsrc", null);
        Element encoder = ElementFactory.make ("wavenc", null);

        if (src == null || encoder == null) {
            throw new GstStreamError.MISSING_PLUGIN ("Required plugin missing");
        }

        // Tell the source to behave like a live source
        src.is_live = true;

        // Add elements to our source bin
        bin.add_many (src, encoder);
        // Link them
        src.link (encoder);

        // Now add the encoder's src pad to the bin
        Pad pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (bin.name + "." + pad.name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}

