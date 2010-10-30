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

    private MediaItem item;

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

        // Set action return arguments
        this.action.set ("TransferID", typeof (uint32), this.transfer_id);

        try {
            this.item = yield this.fetch_item ();
        } catch (Error error) {
            warning (_("Failed to get original URI for '%s': %s"),
                     this.destination_uri,
                     error.message);

            int code;
            if (error is ContentDirectoryError) {
                code = error.code;
            } else {
                code = 719;
            }

            this.action.return_error (code, error.message);
            this.status = TransferStatus.ERROR;
            this.completed ();

            return;
        }

        // We can already return the action now
        this.action.return ();

        var queue = ItemRemovalQueue.get_default ();
        queue.dequeue (this.item);

        try {
            var destination_file = File.new_for_uri (this.item.uris[0]);
            var source_file = File.new_for_uri (source_uri);

            yield source_file.copy_async (destination_file,
                                          FileCopyFlags.OVERWRITE,
                                          Priority.LOW,
                                          this.cancellable,
                                          this.copy_progress_cb);

            this.status = TransferStatus.COMPLETED;

            debug ("Import of '%s' to '%s' completed",
                   source_uri,
                   destination_file.get_uri ());
        } catch (Error err) {
            warning ("%s", err.message);
            this.status = TransferStatus.ERROR;
            yield queue.remove_now (this.item, this.cancellable);
        }

        this.completed ();
    }

    private async MediaItem fetch_item () throws Error {
        var uri = new HTTPItemURI.from_string (this.destination_uri,
                                               this.http_server);
        var media_object = yield this.root_container.find_object (uri.item_id,
                                                                  null);

        string msg = null;

        if (media_object == null || !(media_object is MediaItem)) {
            msg = _("URI '%s' invalid for importing contents to").printf
                                        (this.destination_uri);
        } else if (!(media_object as MediaItem).place_holder) {
            msg = _("Pushing data to non-empty item '%s' not allowed").printf
                                        (media_object.id);
        } else if (media_object.uris.size < 1) {
            assert_not_reached ();
        }

        if (msg != null) {
            throw new ContentDirectoryError.INVALID_ARGS (msg);
        }

        return media_object as MediaItem;
    }

    private void copy_progress_cb (int64 current_num_bytes,
                                   int64 total_num_bytes) {
        this.bytes_copied = current_num_bytes;
        this.bytes_total = total_num_bytes;
    }
}

