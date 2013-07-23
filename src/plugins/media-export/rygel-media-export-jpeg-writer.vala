/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
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

using Gst;

/**
 * Utility class to write media-art content to JPEG files
 *
 * This uses a gstreamer pipeline to transcode the image tag as contained in
 * MP3 files. This class is single-shot, use and then throw away.
 */
internal class Rygel.MediaExport.JPEGWriter : GLib.Object {
    private Bin bin;
    private App.Src appsrc;
    private MainLoop loop;
    private dynamic Element sink;

    public JPEGWriter () throws Error {
        this.bin = Gst.parse_launch ("appsrc name=src ! decodebin ! " +
                                     "autovideoconvert ! " +
                                     "jpegenc ! giosink name=sink") as Bin;
        this.appsrc = bin.get_by_name ("src") as App.Src;
        this.sink = bin.get_by_name ("sink");
        var bus = bin.get_bus ();
        bus.add_signal_watch ();
        bus.message["eos"].connect(() => { this.loop.quit (); });
        bus.message["error"].connect(() => { this.loop.quit (); });
        this.loop = new MainLoop (null, false);
    }

    ~JPEGWriter () {
        this.bin.get_bus ().remove_signal_watch ();
    }

    /**
     * Write a Gst.Buffer as retrieved from the Gst.TagList to disk.
     *
     * @param buffer The Gst.Buffer as obtained from tag list
     * @param file   A GLib.File pointing to the target location
     *
     * FIXME This uses a nested main-loop to block which is ugly.
     */
    public void write (Gst.Buffer buffer, File file) {
        Gst.FlowReturn flow;
        this.sink.file = file;
        Signal.emit_by_name (appsrc, "push-buffer", buffer, out flow);
        this.appsrc.end_of_stream ();
        this.bin.set_state (State.PLAYING);
        this.loop.run ();
        this.bin.set_state (State.NULL);
    }
}
