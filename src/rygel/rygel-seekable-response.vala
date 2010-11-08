/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation.
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

using GUPnP;

internal class Rygel.SeekableResponse : Rygel.HTTPResponse {
    private const size_t BUFFER_LENGTH = 65536;

    private HTTPSeek seek;
    private File file;
    private FileInputStream input_stream;

    private uint8[] buffer;
    private size_t total_length;

    int priority;

    public SeekableResponse (Soup.Server  server,
                             Soup.Message msg,
                             string       uri,
                             HTTPSeek     seek,
                             int64        file_length,
                             Cancellable? cancellable) {
        var partial = seek.length < file_length;

        base (server, msg, partial, cancellable);

        this.seek = seek;
        this.priority = this.get_requested_priority ();
        this.total_length = (size_t) seek.length;

        this.buffer = new uint8[SeekableResponse.BUFFER_LENGTH];
        this.file = File.new_for_uri (uri);
    }

    public override async void run () {
        try {
           this.input_stream = yield this.file.read_async (this.priority,
                                                           this.cancellable);
        } catch (Error err) {
            warning (_("Failed to read from URI: %s: %s"),
                     file.get_uri (),
                     err.message);
            this.end (false, Soup.KnownStatusCode.NOT_FOUND);

            return;
        }

        yield this.perform_seek ();
    }

    private async void perform_seek () {
        try {
            this.input_stream.seek (this.seek.start,
                                    SeekType.SET,
                                    this.cancellable);
        } catch (Error err) {
            // Failed to seek to media segment (defined by first and last
            // byte positions).
            warning (_("Failed to seek to %s-%s on URI %s: %s"),
                     seek.start.to_string (),
                     seek.stop.to_string (),
                     file.get_uri (),
                     err.message);
            this.end (false,
                      Soup.KnownStatusCode.REQUESTED_RANGE_NOT_SATISFIABLE);
            return;
        }

        yield this.start_reading ();
    }

    private async void start_reading () {
        try {
            yield this.read_contents ();
        } catch (IOError.CANCELLED cancelled_err) {
            // This is OK
        } catch (Error err) {
            warning (_("Failed to read contents from URI: %s: %s"),
                     this.file.get_uri (),
                     err.message);
            this.end (false, Soup.KnownStatusCode.NOT_FOUND);

            return;
        }

        yield this.close_stream ();
    }

    private async void read_contents () throws Error {
        var bytes_read = yield this.input_stream.read_async (this.buffer,
                                                             this.priority,
                                                             this.cancellable);
        this.msg.wrote_chunk.connect ((msg) => {
            if (this.run_continue != null) {
                this.run_continue ();
            }
        });

        while (bytes_read > 0) {
            // FIXME: Remove redundant assingment after we bump our vala dep
            //        to 0.11.2
            var data = this.buffer[0:bytes_read];
            this.push_data (data);
            this.total_length -= bytes_read;

            this.run_continue = read_contents.callback;
            // We return from this call when wrote_chunk signal is emitted
            // and the handler we installed before the loop is called for it.
            yield;
            this.run_continue = null;

            if (this.cancellable != null && this.cancellable.is_cancelled ()) {
                break;
            }

            bytes_read = yield this.input_stream.read_async (this.buffer,
                                                             this.priority,
                                                             this.cancellable);
        }
    }

    private async void close_stream () {
        try {
            yield this.input_stream.close_async (this.priority,
                                                 this.cancellable);
        } catch (Error err) {
            warning (_("Failed to close stream to URI %s: %s"),
                     this.file.get_uri (),
                     err.message);
        }

        if (this.cancellable == null || !this.cancellable.is_cancelled ()) {
            this.end (false, Soup.KnownStatusCode.NONE);
        }
    }

    private int get_requested_priority () {
        var mode = this.msg.request_headers.get_one ("transferMode.dlna.org");

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

