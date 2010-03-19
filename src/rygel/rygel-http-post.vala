/*
 * Copyright (C) 2008-2010 Nokia Corporation.
 * Copyright (C) 2006, 2007, 2008 OpenedHand Ltd.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jorn Baayen <jorn.baayen@gmail.com>
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

using Soup;

/**
 * Responsible for handling HTTP POST client requests.
 */
internal class Rygel.HTTPPost : HTTPRequest {
    SourceFunc handle_continue;

    File file;
    OutputStream stream;

    public HTTPPost (HTTPServer   http_server,
                     Soup.Server  server,
                     Soup.Message msg) {
        base (http_server, server, msg);
    }

    protected override async void handle () {
        this.msg.got_chunk.connect (this.on_got_chunk);
        this.msg.got_body.connect (this.on_got_body);

        this.server.pause_message (this.msg);
        yield base.handle ();

        try {
            this.file = yield this.item.get_writable (this.cancellable);
            if (this.file == null) {
                throw new HTTPRequestError.BAD_REQUEST (
                                        "No writable URI for %s available",
                                        this.item.id);
            }

            this.stream = yield this.file.replace_async (
                                        null,
                                        false,
                                        FileCreateFlags.REPLACE_DESTINATION,
                                        Priority.LOW,
                                        this.cancellable);
        } catch (Error error) {
            this.server.unpause_message (this.msg);
            this.handle_error (error);

            return;
        }

        this.server.unpause_message (this.msg);
        this.handle_continue = this.handle.callback;

        yield;
    }

    private void on_got_body (Message msg) {
        if (this.msg == msg) {
            this.end (KnownStatusCode.OK);

            this.handle_continue ();
        }
    }

    private void on_got_chunk (Message msg, Buffer chunk) {
        this.write_chunk.begin (chunk);
    }

    private async void write_chunk (Buffer chunk) {
        try {
            this.stream.write (chunk.data, chunk.length, this.cancellable);
        } catch (Error error) {
            this.handle_error (error);
            this.handle_continue ();
        }
    }
}

