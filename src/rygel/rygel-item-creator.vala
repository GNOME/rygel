/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

private errordomain Rygel.ItemCreatorError {
    PARSE
}

/**
 * CreateObject action implementation.
 */
internal class Rygel.ItemCreator: GLib.Object, Rygel.StateMachine {
    // In arguments
    public string container_id;
    public string elements;

    public DIDLLiteItem didl_item;
    public MediaItem item;

    private ContentDirectory content_dir;
    private ServiceAction action;
    private Rygel.DIDLLiteWriter didl_writer;
    private DIDLLiteParser didl_parser;

    public Cancellable cancellable { get; set; }

    public ItemCreator (ContentDirectory    content_dir,
                        owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
        this.didl_writer = new Rygel.DIDLLiteWriter (content_dir.http_server);
        this.didl_parser = new DIDLLiteParser ();
    }

    public async void run () {
        try {
            this.parse_args ();

            var container = yield this.fetch_container ();

            this.didl_parser.item_available.connect ((didl_item) => {
                    this.didl_item = didl_item;
            });
            this.didl_parser.parse_didl (this.elements);
            if (this.didl_item == null) {
                throw new ItemCreatorError.PARSE ("Failed to find any item " +
                                                  "in DIDL-Lite from client: " +
                                                  this.elements);
            }

            this.item = new MediaItem (didl_item.id,
                                       container,
                                       didl_item.title,
                                       didl_item.upnp_class);
            this.item.mime_type = this.get_generic_mime_type ();
            this.item.place_holder = true;

            yield container.add_item (this.item, this.cancellable);
            this.didl_writer.serialize (this.item);

            // Conclude the successful action
            this.conclude ();
        } catch (Error err) {
            this.handle_error (err);
        }
    }

    private async void parse_args () throws Error {
        /* Start by parsing the 'in' arguments */
        this.action.get ("ContainerID", typeof (string), out this.container_id,
                         "Elements", typeof (string), out this.elements);

        if (this.container_id == null || this.elements == null) {
            // Sorry we can't do anything without ContainerID
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }
    }

    private async MediaContainer fetch_container () throws Error {
        var media_object = yield this.content_dir.root_container.find_object (
                                        this.container_id,
                                        this.cancellable);
        if (media_object == null || !(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return media_object as MediaContainer;
    }

    private void conclude () {
        /* Retrieve generated string */
        string didl = this.didl_writer.get_string ();

        /* Set action return arguments */
        this.action.set ("Result", typeof (string), didl,
                         "ObjectID", typeof (string), this.item.id);

        this.action.return ();
        this.completed ();
    }

    private void handle_error (Error error) {
        if (error is ContentDirectoryError) {
            this.action.return_error (error.code, error.message);
        } else {
            this.action.return_error (701, error.message);
        }

        warning ("Failed to create item under '%s': %s",
                 this.container_id,
                 error.message);

        this.completed ();
    }

    private string get_generic_mime_type () {
        switch (this.item.upnp_class) {
            case MediaItem.IMAGE_CLASS:
                return "image";
            case MediaItem.VIDEO_CLASS:
                return "video";
            case MediaItem.AUDIO_CLASS:
            default:
                return "audio";
        }
    }
}

