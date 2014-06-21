/*
 * Copyright (C) 2008-2010 Nokia Corporation.
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
using Soup;

internal enum Rygel.TransferStatus {
    COMPLETED,
    ERROR,
    IN_PROGRESS,
    STOPPED
}

/**
 * Responsible for handling ImportResource action.
 */
internal class Rygel.ImportResource : GLib.Object, Rygel.StateMachine {
    private static uint32 last_transfer_id = 0;

    // In arguments
    public string source_uri;
    public string destination_uri;

    // Out arguments
    public uint32 transfer_id;

    public TransferStatus status;
    public int64 bytes_copied;
    public int64 bytes_total;

    private MediaFileItem item;
    private Session session;

    public string status_as_string {
        get {
            switch (this.status) {
                case TransferStatus.COMPLETED:
                    return "COMPLETED";
                case TransferStatus.ERROR:
                    return "ERROR";
                case TransferStatus.IN_PROGRESS:
                    return "IN_PROGRESS";
                case TransferStatus.STOPPED:
                default:
                    return "STOPPED";
            }
        }
    }

    public Cancellable cancellable { get; set; }

    private HTTPServer http_server;
    private MediaContainer root_container;
    private ServiceAction action;
    private SourceFunc run_callback;
    private FileOutputStream output_stream;

    public ImportResource (ContentDirectory    content_dir,
                           owned ServiceAction action) {
        this.root_container = content_dir.root_container;
        this.http_server = content_dir.http_server;
        this.cancellable = new Cancellable ();
        this.action = (owned) action;

        last_transfer_id++;
        this.transfer_id = last_transfer_id;

        this.bytes_copied = 0;
        this.bytes_total = 0;

        this.status = TransferStatus.IN_PROGRESS;
        this.session = new Session ();

        content_dir.cancellable.cancelled.connect (() => {
            this.cancellable.cancel ();
        });
    }

    public async void run () {
        // Start by parsing the 'in' arguments
        this.action.get ("SourceURI",
                            typeof (string),
                            out this.source_uri,
                         "DestinationURI",
                            typeof (string),
                            out this.destination_uri);

        try {
            if (this.source_uri == null) {
                throw new ContentDirectoryError.INVALID_ARGS
                                        ("Must provide source URI");
            }

            if (this.destination_uri == null) {
                throw new ContentDirectoryError.NO_SUCH_DESTINATION_RESOURCE
                                        ("Must provide destination URI");
            }

            // Set action return arguments
            this.action.set ("TransferID", typeof (uint32), this.transfer_id);

            this.item = yield this.fetch_item ();
        } catch (Error error) {
            warning (_("Failed to get original URI for '%s': %s"),
                     this.destination_uri,
                     error.message);

            this.action.return_error (error.code, error.message);
            this.status = TransferStatus.ERROR;
            this.completed ();

            return;
        }

        var queue = ObjectRemovalQueue.get_default ();
        queue.dequeue (this.item);

        try {
            var source_file = File.new_for_uri (this.item.get_primary_uri ());
            this.output_stream = yield source_file.replace_async (null,
                                                                  false,
                                                                  FileCreateFlags.PRIVATE,
                                                                  Priority.DEFAULT,
                                                                  this.cancellable);
            var message = new Message ("GET", source_uri);
            message.got_chunk.connect (this.got_chunk_cb);
            message.got_body.connect (this.got_body_cb);
            message.got_headers.connect (this.got_headers_cb);
            message.finished.connect (this.finished_cb);
            message.response_body.set_accumulate (false);

            this.run_callback = run.callback;
            this.session.queue_message (message, null);

            debug ("Importing resource from %s to %s",
                   source_uri,
                   this.item.get_primary_uri ());

            yield;
        } catch (Error err) {
            warning ("%s", err.message);
            this.status = TransferStatus.ERROR;
            yield queue.remove_now (this.item, this.cancellable);
        }

        this.completed ();
    }

    private async MediaFileItem fetch_item () throws Error {
        HTTPItemURI uri;
        try {
            uri = new HTTPItemURI.from_string (this.destination_uri,
                                               this.http_server);
        } catch (Error error) {
            throw new ContentDirectoryError.NO_SUCH_DESTINATION_RESOURCE
                                            (error.message);
        }
        var media_object = yield this.root_container.find_object (uri.item_id,
                                                                  null);
        string msg = null;

        if (media_object == null ||
            !(media_object is MediaFileItem) ||
            !(media_object.parent is WritableContainer)) {
            msg = _("URI '%s' invalid for importing contents to").printf
                                        (this.destination_uri);
        } else if (!(media_object as MediaFileItem).place_holder) {
            msg = _("Pushing data to non-empty item '%s' not allowed").printf
                                        (media_object.id);
        } else if (media_object.get_uris ().is_empty) {
            assert_not_reached ();
        }

        if (msg != null) {
            throw new ContentDirectoryError.INVALID_ARGS (msg);
        }

        return media_object as MediaFileItem;
    }

    private void got_headers_cb (Message message) {
        this.bytes_total = message.response_headers.get_content_length ();

        if (message.status_code >= 200 && message.status_code <= 299) {
            this.action.return ();
        } else {
            this.handle_transfer_error (message);
        }

        this.action = null;
    }

    private void got_chunk_cb (Message message, Buffer buffer) {
        this.bytes_copied += buffer.length;
        try {
            size_t bytes_written;

            this.output_stream.write_all (buffer.data,
                                          out bytes_written,
                                          this.cancellable);
        } catch (Error error) {
            warning ("%s", error.message);
            if (error is IOError.CANCELLED) {
                this.status = TransferStatus.STOPPED;
            } else {
                this.status = TransferStatus.ERROR;
            }
            this.session.cancel_message (message, Status.CANCELLED);
        }
    }

    private void got_body_cb (Message message) {
        if (this.bytes_total == 0) {
            this.bytes_total = this.bytes_copied;
        } else if (this.bytes_total != this.bytes_copied) {
            this.status = TransferStatus.ERROR;

            return;
        }

        try {
            this.output_stream.close (this.cancellable);
            if (this.status == TransferStatus.IN_PROGRESS) {
                this.status = TransferStatus.COMPLETED;
            }
        } catch (Error error) {
            warning ("%s", error.message);
            this.status = TransferStatus.ERROR;
        }
    }

    private void finished_cb (Message message) {
        if (this.status == TransferStatus.IN_PROGRESS) {
            if (!(message.status_code >= 200 && message.status_code <= 299)) {
                this.handle_transfer_error (message);
            }
        }

        this.run_callback ();
    }

    private void handle_transfer_error (Message message) {
        this.status = TransferStatus.ERROR;
        try {
            this.output_stream.close (this.cancellable);
            var file = File.new_for_uri (this.item.get_primary_uri ());
            file.delete (this.cancellable);
        } catch (Error error) {};

        var phrase = Status.get_phrase (message.status_code);
        warning (_("Failed to import file from %s: %s"),
                 this.source_uri,
                 phrase);

        if (action == null) {
            return;
        }

        if (message.status_code == Soup.Status.NOT_FOUND ||
            message.status_code < 100) {
            this.action.return_error (714, phrase);
        } else {
            this.action.return_error (715, phrase);
        }
    }
}
