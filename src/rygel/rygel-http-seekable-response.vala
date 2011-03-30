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

internal class Rygel.HTTPSeekableResponse : Rygel.HTTPResponse {
    private const size_t BUFFER_LENGTH = 65536;

    private HTTPSeek seek;
    private File file;
    private FileInputStream input_stream;

    private uint8[] buffer;
    private size_t total_length;

    public HTTPSeekableResponse (HTTPGet        request,
                                 HTTPGetHandler request_handler) throws Error {
        string uri;
        int64 file_length;

        if (request.subtitle != null) {
            uri = request.subtitle.uri;
            file_length = request.subtitle.size;
        } else if (request.thumbnail != null) {
            uri = request.thumbnail.uri;
            file_length = request.thumbnail.size;
        } else {
            var item = request.item;

            if (item.uris.size == 0) {
                throw new HTTPRequestError.NOT_FOUND
                                        (_("Item '%s' didn't provide a URI"),
                                         item.id);
            }

            uri = item.uris.get (0);
            file_length = item.size;
        }

        var partial = request.seek.length < file_length;

        base (request, request_handler, partial);

        this.msg.response_headers.set_encoding (Soup.Encoding.CONTENT_LENGTH);

        this.seek = request.seek;
        this.total_length = (size_t) this.seek.length;

        if (this.total_length > BUFFER_LENGTH) {
            this.buffer = new uint8[HTTPSeekableResponse.BUFFER_LENGTH];
        } else {
            this.buffer = new uint8[this.total_length];
        }

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
            var to_push = size_t.min (bytes_read, this.total_length);

            this.push_data (this.buffer[0:to_push]);
            this.total_length -= to_push;

            if (this.total_length <= 0) {
                break;
            }

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
}

