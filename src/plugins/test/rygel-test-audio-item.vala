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

public errordomain Rygel.TestError {
    MISSING_PLUGIN
}

/**
 * Represents Test audio item.
 */
public class Rygel.TestAudioItem : Rygel.MediaItem {
    const string TEST_PATH = "/test.wav";
    const string TEST_MIMETYPE = "audio/x-wav";
    const string TEST_AUTHOR = "Zeeshan Ali (Khattak)";

    private Streamer streamer;
    private HashMap<Stream,StreamContext> streams;

    public TestAudioItem (string   id,
                          string   parent_id,
                          string   title,
                          Streamer streamer) {
        base (id, parent_id, title, MediaItem.AUDIO_CLASS);
        this.mime = TEST_MIMETYPE;
        this.author = TEST_AUTHOR;
        this.uri = streamer.create_uri_for_path (TEST_PATH);
        this.streams = new HashMap<Stream,StreamContext> ();

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

        StreamContext context;

        try {
            Element src = this.create_gst_source ();
            context = new StreamContext (stream, "RygelStreamer", src);
        } catch (Error error) {
            critical ("Error creating stream context: %s", error.message);

            return;
        }

        context.set_state (State.PLAYING);
        stream.eos += on_eos;

        this.streams.set (stream, context);
    }

    private void on_eos (Stream stream) {
        StreamContext context = this.streams.get (stream);
        if (context == null)
            return;

        /* We don't need to wait for state change since downstream state changes
         * are guaranteed to be synchronous.
         */
        context.set_state (State.NULL);

        /* Remove the associated context. */
        this.streams.remove (stream);
    }

    private Element create_gst_source () throws Error {
        Bin bin = new Bin (this.title);

        Element src = ElementFactory.make ("audiotestsrc", null);
        Element encoder = ElementFactory.make ("wavenc", null);

        if (src == null || encoder == null) {
            throw new TestError.MISSING_PLUGIN ("Required plugin missing");
        }

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

private class StreamContext : Pipeline {
    public Stream stream;

    private AsyncQueue<Buffer> buffers;

    public StreamContext (Stream  stream,
                          string  name,
                          Element src) throws Error {
        this.stream = stream;
        this.name = name;
        this.buffers = new AsyncQueue<Buffer> ();

        this.stream.accept ();
        this.stream.set_mime_type (TestAudioItem.TEST_MIMETYPE);
        this.prepare_pipeline (src);
    }

    private void prepare_pipeline (Element src) throws Error {
        dynamic Element sink = ElementFactory.make ("appsink", null);

        if (sink == null) {
            throw new TestError.MISSING_PLUGIN ("Required plugin " +
                                                "'appsink' missing");
        }

        sink.emit_signals = true;
        sink.new_buffer += this.on_new_buffer;
        sink.new_preroll += this.on_new_preroll;

        this.add_many (src, sink);
        src.link (sink);
    }

    private void on_new_buffer (dynamic Element sink) {
        Buffer buffer = null;

        GLib.Signal.emit_by_name (sink, "pull-buffer", out buffer);
        if (buffer == null) {
            critical ("Failed to get buffer from pipeline");
            return;
        }

        this.queue_buffer (buffer);
    }

    private void on_new_preroll (dynamic Element sink) {
        Buffer buffer = null;

        GLib.Signal.emit_by_name (sink, "pull-preroll", out buffer);
        if (buffer == null) {
            critical ("Failed to get buffer from pipeline");
            return;
        }

        this.queue_buffer (buffer);
    }

    private void queue_buffer (Buffer buffer) {
        this.buffers.push (buffer);
        Idle.add_full (Priority.HIGH_IDLE, this.idle_handler);
    }

    private bool idle_handler () {
        var buffer = this.buffers.pop ();

        if (buffer != null) {
            this.stream.push_data (buffer.data, buffer.size);
        }

        return false;
    }
}

