/*
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

using Gee;
using Gst;

public class Rygel.Streamer : GLib.Object {
    private string server_path_root;

    private GUPnP.Context context;
    private HashMap<Stream,GstStream> streams;

    public signal void stream_available (Rygel.Stream stream,
                                         string       path);

    public Streamer (GUPnP.Context context, string name) {
        this.context = context;
        this.streams = new HashMap<Stream,GstStream> ();

        this.server_path_root = "/" + name;

        context.server.add_handler (this.server_path_root, server_handler);
    }

    public string create_uri_for_path (string path) {
        return "http://%s:%u%s%s".printf (this.context.host_ip,
                                          this.context.port,
                                          this.server_path_root,
                                          path);
    }

    public void stream_from_gst_source (Element# src,
                                        Stream   stream) throws Error {
        GstStream gst_stream;

        gst_stream = new GstStream (stream, "RygelGstStream", src);

        gst_stream.set_state (State.PLAYING);
        stream.eos += on_eos;

        this.streams.set (stream, gst_stream);
    }

    private void on_eos (Stream stream) {
        GstStream gst_stream = this.streams.get (stream);
        if (gst_stream == null)
            return;

        /* We don't need to wait for state change since downstream state changes
         * are guaranteed to be synchronous.
         */
        gst_stream.set_state (State.NULL);

        /* Remove the associated Gst stream. */
        this.streams.remove (stream);
    }

    private void server_handler (Soup.Server        server,
                                 Soup.Message       msg,
                                 string             server_path,
                                 HashTable?         query,
                                 Soup.ClientContext soup_client) {
        string[] path_tokens = server_path.split (this.server_path_root, 2);
        if (path_tokens[0] == null || path_tokens[1] == null) {
            msg.set_status (Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        string stream_path = path_tokens[1];
        var stream = new Stream (server, msg);

        this.stream_available (stream, stream_path);
    }
}

