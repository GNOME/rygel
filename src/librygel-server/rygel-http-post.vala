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
    File dotfile;
    OutputStream stream;

    public HTTPPost (HTTPServer   http_server,
                     Soup.Server  server,
                     Soup.Message msg) {
        base (http_server, server, msg);

        this.cancellable.connect (this.on_request_cancelled);
        msg.request_body.set_accumulate (false);
    }

    protected override async void handle () throws Error {
        var queue = ObjectRemovalQueue.get_default ();
        queue.dequeue (this.object);

        try {
            yield this.handle_real ();
        } catch (Error error) {
            yield queue.remove_now (this.object, this.cancellable);

            throw error;
        }
    }

    private async void handle_real () throws Error {
        if (!(this.object as MediaFileItem).place_holder) {
            var msg = _("Pushing data to non-empty item '%s' not allowed");

            throw new ContentDirectoryError.INVALID_ARGS (msg, this.object.id);
        }

        this.file = yield (this.object as MediaFileItem).get_writable
                                        (this.cancellable);
        if (this.file == null) {
            throw new HTTPRequestError.BAD_REQUEST
                                        (_("No writable URI for %s available"),
                                         this.object.id);
        }

        this.dotfile = this.file.get_parent ().get_child
                                        ("." + this.file.get_basename ());
        this.stream = yield this.dotfile.replace_async
                                        (null,
                                         false,
                                         FileCreateFlags.REPLACE_DESTINATION,
                                         Priority.LOW,
                                         this.cancellable);

        this.msg.got_chunk.connect (this.on_got_chunk);
        this.msg.got_body.connect (this.on_got_body);

        this.server.unpause_message (this.msg);
        this.handle_continue = this.handle_real.callback;

        yield;
    }

    private void on_got_body (Message msg) {
        if (this.msg != msg) {
            return;
        }

        this.finalize_post.begin ();
    }

    /**
     * Waits for an item with @id to change its state to non-placeholder under
     * @container, but at most @timeout seconds.
     *
     * @param container The container to watch for changes
     * @param id The child id to look for
     * @param timeout Seconds to wait befor cancelling
     */
    private async void wait_for_item (MediaContainer container,
                                      string         id,
                                      uint           timeout) {
        MediaFileItem item = null;

        while (item == null || item.place_holder) {
            try {
                item = (yield container.find_object (id,
                                                     this.cancellable))
                                                     as MediaFileItem;
            } catch (Error error) {
                // Handle
                break;
            }

            // This means that either someone externally has removed the item
            // or that the back-end decided it's not a shareable item anymore.
            if (item == null) {
                warning ("Item %s disappeared, stop waiting for it", id);

                break;
            }

            if (item.place_holder) {
                uint source_id = 0;
                source_id = Timeout.add_seconds (timeout, () => {
                    debug ("Timeout on waiting for 'updated' signal on '%s'.",
                           container.id);
                    source_id = 0;
                    this.wait_for_item.callback ();

                    return false;
                });

                var update_id = container.container_updated.connect (() => {
                    debug ("Finished waiting for update signal from container '%s'",
                           container.id);

                        wait_for_item.callback ();
                });

                yield;

                container.disconnect (update_id);

                if (source_id != 0) {
                    Source.remove (source_id);
                } else {
                    break;
                }
            }
        }
    }

    private async void finalize_post () {
        try {
            this.stream.close (this.cancellable);
        } catch (Error error) {
            this.end (Status.INTERNAL_SERVER_ERROR);
            this.handle_continue ();

            return;
        }

        this.server.pause_message (this.msg);

        debug ("Waiting for update signal from container '%s' after pushing" +
               " content to its child item '%s'…",
               this.object.parent.id,
               this.object.id);

        try {
            this.dotfile.move (this.file,
                               FileCopyFlags.NONE,
                               this.cancellable);
        } catch (Error move_error) {
            // translators: Dotfile is the filename with prefix "."
            warning (_("Failed to move dotfile %s: %s"),
                     this.dotfile.get_uri (),
                     move_error.message);

            this.server.unpause_message (this.msg);
            this.end (Status.INTERNAL_SERVER_ERROR);
            this.handle_continue ();

            return;
        }

        yield wait_for_item (this.object.parent, this.object.id, 5);

        this.server.unpause_message (this.msg);
        this.end (Status.OK);
        this.handle_continue ();
    }

    private void on_got_chunk (Message msg, Buffer chunk) {
        try {
            this.stream.write_all (chunk.data, null, this.cancellable);
        } catch (Error error) {
            this.disconnect_message_signals ();
            this.handle_error (
                new HTTPRequestError.INTERNAL_SERVER_ERROR (error.message));
            this.handle_continue ();
        }
    }

    private void on_request_cancelled () {
        this.remove_item.begin ();
    }

    private async void remove_item () {
        var queue = ObjectRemovalQueue.get_default ();
        yield queue.remove_now (this.object as MediaFileItem, null);
    }

    private void disconnect_message_signals () {
        this.msg.got_body.disconnect (this.on_got_body);
        this.msg.got_chunk.disconnect (this.on_got_chunk);
    }

}
