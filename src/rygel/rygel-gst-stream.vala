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

public errordomain Rygel.GstStreamError {
    MISSING_PLUGIN
}

public class Rygel.GstStream : Pipeline {
    public Stream stream;

    private AsyncQueue<Buffer> buffers;

    public GstStream (Stream  stream,
                      string  name,
                      Element src) throws Error {
        this.stream = stream;
        this.name = name;
        this.buffers = new AsyncQueue<Buffer> ();

        this.stream.accept ();
        this.prepare_pipeline (src);
    }

    private void prepare_pipeline (Element src) throws Error {
        dynamic Element sink = ElementFactory.make ("fakesink", null);

        if (sink == null) {
            throw new GstStreamError.MISSING_PLUGIN ("Required plugin " +
                                                     "'appsink' missing");
        }

        sink.signal_handoffs = true;
        sink.handoff += this.on_new_buffer;

        this.add_many (src, sink);
        src.link (sink);

        // Bus handler
        var bus = this.get_bus ();
        bus.add_watch (bus_handler);
    }

    private void on_new_buffer (Element sink,
                                Buffer  buffer,
                                Pad     pad) {
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

    private bool bus_handler (Gst.Bus     bus,
                              Gst.Message message) {
        bool ret = true;

        if (message.type == MessageType.EOS) {
            ret = false;
        } else {
            GLib.Error err;
            string err_msg;

            if (message.type == MessageType.ERROR) {
                message.parse_error (out err, out err_msg);
                critical ("Error from pipeline %s:%s", this.name, err_msg);

                ret = false;
            } else if (message.type == MessageType.WARNING) {
                message.parse_warning (out err, out err_msg);
                warning ("Warning from pipeline %s:%s", this.name, err_msg);
            }
        }

        if (!ret) {
            this.stream.end ();
        }

        return ret;
    }
}

