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
    private static PatternSpec comment_pattern = new PatternSpec ("*<!--*-->*");

    // In arguments
    public string container_id;
    public string elements;

    public DIDLLiteItem didl_item;
    public MediaItem item;

    private ContentDirectory content_dir;
    private ServiceAction action;
    private DIDLLiteWriter didl_writer;
    private DIDLLiteParser didl_parser;

    public Cancellable cancellable { get; set; }

    public ItemCreator (ContentDirectory    content_dir,
                        owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
        this.didl_writer = new DIDLLiteWriter (null);
        this.didl_parser = new DIDLLiteParser ();
    }

    public async void run () {
        try {
            this.parse_args ();

            this.didl_parser.item_available.connect ((didl_item) => {
                    this.didl_item = didl_item;
            });
            this.didl_parser.parse_didl (this.elements);
            if (this.didl_item == null) {
                var message = _("No items in DIDL-Lite from client: '%s'");

                throw new ItemCreatorError.PARSE (message, this.elements);
            }

            var container = yield this.fetch_container ();

            this.item = this.create_item (didl_item.id,
                                          container,
                                          didl_item.title,
                                          didl_item.upnp_class);

            var resources = didl_item.get_resources ();
            if (resources != null && resources.length () > 0) {
                var resource = resources.nth (0).data;
                var info = resource.protocol_info;

                if (info != null) {
                    if (info.dlna_profile != null) {
                        this.item.dlna_profile = info.dlna_profile;
                    }

                    if (info.mime_type != null) {
                        this.item.mime_type = info.mime_type;
                    }
                }

                if (this.is_valid_uri (resource.uri)) {
                    this.item.add_uri (resource.uri);
                }

                if (resource.size >= 0) {
                    this.item.size = resource.size;
                }
            }

            if (this.item.mime_type == null) {
                this.item.mime_type = this.get_generic_mime_type ();
            }

            if (this.item.size < 0) {
                this.item.size = 0;
            }

            if (this.item.uris.size == 0) {
                var uri = yield this.create_uri (container, this.item.title);
                this.item.uris.add (uri);
            }

            this.item.id = this.item.uris[0];

            yield container.add_item (this.item, this.cancellable);
            this.item.serialize (didl_writer, this.content_dir.http_server);

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

        if (this.elements == null) {
            throw new ContentDirectoryError.BAD_METADATA (
                                        _("'Elements' argument missing."));
        } else if (comment_pattern.match_string (this.elements)) {
            throw new ContentDirectoryError.BAD_METADATA (
                                        _("Comments not allowed in XML"));
        }

        if (this.container_id == null) {
            // Sorry we can't do anything without ContainerID
            throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                        _("No such object"));
        }
    }

    private async MediaContainer fetch_container () throws Error {
        MediaObject media_object = null;

        if (this.container_id == "DLNA.ORG_AnyContainer") {
            var expression = new RelationalExpression ();
            expression.op = SearchCriteriaOp.DERIVED_FROM;
            expression.operand1 = "upnp:createClass";
            expression.operand2 = didl_item.upnp_class;

            uint total_matches;

            var result = yield this.content_dir.root_container.search (
                                        expression,
                                        0,
                                        1,
                                        out total_matches,
                                        this.cancellable);
            if (result.size > 0) {
                media_object = result[0];
                this.container_id = media_object.id;
            }
        } else {
            media_object = yield this.content_dir.root_container.find_object (
                                        this.container_id,
                                        this.cancellable);
        }

        if (media_object == null || !(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT (
                                        _("No such object"));
        }

        return media_object as MediaContainer;
    }

    private void conclude () {
        /* Retrieve generated string */
        string didl = this.didl_writer.get_string ();

        /* Set action return arguments */
        this.action.set ("ObjectID", typeof (string), this.item.id,
                         "Result", typeof (string), didl);

        this.action.return ();
        this.completed ();
    }

    private void handle_error (Error error) {
        if (error is ContentDirectoryError) {
            this.action.return_error (error.code, error.message);
        } else {
            this.action.return_error (701, error.message);
        }

        warning (_("Failed to create item under '%s': %s"),
                 this.container_id,
                 error.message);

        this.completed ();
    }

    private string get_generic_mime_type () {
        if (this.item is ImageItem) {
            return "image";
        } else if (this.item is VideoItem) {
            return "video";
        } else {
            return "audio";
        }
    }

    private MediaItem create_item (string         id,
                                   MediaContainer parent,
                                   string         title,
                                   string         upnp_class) throws Error {
        switch (upnp_class) {
        case ImageItem.UPNP_CLASS:
            return new ImageItem (id, parent, title);
        case PhotoItem.UPNP_CLASS:
            return new PhotoItem (id, parent, title);
        case VideoItem.UPNP_CLASS:
            return new VideoItem (id, parent, title);
        case AudioItem.UPNP_CLASS:
            return new AudioItem (id, parent, title);
        case MusicItem.UPNP_CLASS:
            return new MusicItem (id, parent, title);
        default:
            throw new ContentDirectoryError.BAD_METADATA (
                                        "Creation of item of class '%s' " +
                                        "not supported.",
                                         upnp_class);
        }
    }

    // FIXME: This function is hardly completely. Perhaps we should just make
    // use of a regex here.
    private bool is_valid_uri (string? uri) {
        if (uri == null || uri == "") {
            return false;
        }

        for (var next = uri.next_char ();
             next != "";
             next = next.next_char ()) {
            if (next.get_char ().isspace ()) {
                return false;
            }
        }

        return true;
    }

    public async string create_uri (MediaContainer container, string title)
                                    throws Error {
        var dir = yield container.get_writable (this.cancellable);
        if (dir == null) {
            throw new ContentDirectoryError.RESTRICTED_PARENT (
                                        _("Object creation in %s not allowed"),
                                        container.id);
        }

        var file = dir.get_child_for_display_name (title);

        return file.get_uri ();
    }
}

