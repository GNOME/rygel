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

    protected override async void handle () throws Error {
        var queue = ItemRemovalQueue.get_default ();
        queue.dequeue (this.item);

        try {
            yield this.handle_real ();
        } catch (Error error) {
            yield queue.remove_now (this.item, this.cancellable);

            throw error;
        }
    }

    private async void handle_real () throws Error {
        this.msg.got_chunk.connect (this.on_got_chunk);
        this.msg.got_body.connect (this.on_got_body);

        if (!this.item.place_holder) {
            var msg = _("Pushing data to non-empty item '%s' not allowed");

            throw new ContentDirectoryError.INVALID_ARGS (msg, this.item.id);
        }

        this.file = yield this.item.get_writable (this.cancellable);
        if (this.file == null) {
            throw new HTTPRequestError.BAD_REQUEST
                                        (_("No writable URI for %s available"),
                                         this.item.id);
        }

        this.stream = yield this.file.replace_async
                                        (null,
                                         false,
                                         FileCreateFlags.REPLACE_DESTINATION,
                                         Priority.LOW,
                                         this.cancellable);

        this.server.unpause_message (this.msg);
        this.handle_continue = this.handle.callback;

        yield;
    }

    private void on_got_body (Message msg) {
        if (this.msg != msg) {
            return;
        }

        var main_loop = new MainLoop ();

        this.item.parent.container_updated.connect ((container) => {
            main_loop.quit ();
        });

        Timeout.add_seconds (5, () => {
            debug ("Timeout while waiting for 'updated' signal on '%s'.",
                   this.item.parent.id);
            main_loop.quit ();

            return false;
        });

        debug ("Waiting for update signal from container '%s' after pushing" +
               " content to its child item '%s'..",
               this.item.parent.id,
               this.item.id);
        main_loop.run ();
        debug ("Finished waiting for update signal from container '%s'",
               this.item.parent.id);

        this.end (KnownStatusCode.OK);
        this.handle_continue ();
    }

    private void on_got_chunk (Message msg, Buffer chunk) {
        this.write_chunk.begin (chunk);
    }

    private async void write_chunk (Buffer chunk) {
        try {
            this.stream.write (chunk.data, this.cancellable);
        } catch (Error error) {
            this.handle_error (error);
            this.handle_continue ();
        }
    }
}

