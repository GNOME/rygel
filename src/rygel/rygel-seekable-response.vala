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

internal class Rygel.SeekableResponse : Rygel.HTTPResponse {
    private const size_t BUFFER_LENGTH = 4096;

    private Seek seek;
    private File file;
    private FileInputStream input_stream;

    private char[] buffer;
    private size_t total_length;

    int priority;

    public SeekableResponse (Soup.Server  server,
                             Soup.Message msg,
                             string       uri,
                             Seek?        seek,
                             size_t       file_length) {
        base (server, msg, seek != null);

        this.seek = seek;
        this.total_length = file_length;
        this.priority = this.get_requested_priority ();

        if (seek != null) {
            this.total_length = (size_t) seek.length;
        } else {
            this.total_length = file_length;
        }

        msg.wrote_chunk += on_wrote_chunk;

        this.buffer = new char[SeekableResponse.BUFFER_LENGTH];
        this.file = File.new_for_uri (uri);
    }

    public override void run (Cancellable? cancellable) {
        this.cancellable = cancellable;

        this.file.read_async (this.priority, cancellable, this.on_file_read);
    }

    private void on_file_read (GLib.Object      source_object,
                               GLib.AsyncResult result) {
        try {
           this.input_stream = this.file.read_finish (result);
        } catch (Error err) {
            warning ("Failed to read from URI: %s: %s\n",
                     file.get_uri (),
                     err.message);
            this.end (false, Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        if (seek != null) {
            try {
                this.input_stream.seek (seek.start,
                                        SeekType.SET,
                                        this.cancellable);
            } catch (Error err) {
                warning ("Failed to seek to %s-%s on URI %s: %s\n",
                         seek.start.to_string (),
                         seek.stop.to_string (),
                         file.get_uri (),
                         err.message);
                this.end (false,
                          Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE);
                return;
            }
        }

        this.input_stream.read_async (this.buffer,
                                 SeekableResponse.BUFFER_LENGTH,
                                 this.priority,
                                 this.cancellable,
                                 on_contents_read);
    }

    private void on_contents_read (GLib.Object      source_object,
                                   GLib.AsyncResult result) {
        FileInputStream input_stream = (FileInputStream) source_object;
        ssize_t bytes_read;

        try {
           bytes_read = input_stream.read_finish (result);
        } catch (Error err) {
            warning ("Failed to read contents from URI: %s: %s\n",
                     this.file.get_uri (),
                     err.message);
            this.end (false, Soup.KnownStatusCode.NOT_FOUND);
            return;
        }

        if (bytes_read > 0) {
            this.push_data (this.buffer, bytes_read);
        } else {
            input_stream.close_async (this.priority,
                                      this.cancellable,
                                      on_input_stream_closed);
        }
    }

    private void on_input_stream_closed (GLib.Object      source_object,
                                         GLib.AsyncResult result) {
        FileInputStream input_stream = (FileInputStream) source_object;

        try  {
            input_stream.close_finish (result);
        } catch (Error err) {
            warning ("Failed to close stream to URI %s: %s\n",
                     this.file.get_uri (),
                     err.message);
        }

        this.end (false, Soup.KnownStatusCode.NONE);
    }

    private void on_wrote_chunk (Soup.Message msg) {
        this.input_stream.read_async (this.buffer,
                                      SeekableResponse.BUFFER_LENGTH,
                                      this.priority,
                                      this.cancellable,
                                      this.on_contents_read);
    }

    private int get_requested_priority () {
        var mode = this.msg.request_headers.get ("transferMode.dlna.org");

        if (mode == null || mode == "Interactive") {
            return Priority.DEFAULT;
        } else if (mode == "Streaming") {
            return Priority.HIGH;
        } else if (mode == "Background") {
            return Priority.LOW;
        } else {
            return Priority.DEFAULT;
        }
    }
}

