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
using Gst;

private errordomain Rygel.ItemCreatorError {
    PARSE
}

/**
 * CreateObject action implementation.
 */
internal class Rygel.ItemCreator: GLib.Object, Rygel.StateMachine {
    private static PatternSpec comment_pattern = new PatternSpec ("*<!--*-->*");

    private const string INVALID_CHARS = "/?<>\\:*|\"";

    // In arguments
    public string container_id;
    public string elements;

    public DIDLLiteItem didl_item;
    public MediaItem item;

    private ContentDirectory content_dir;
    private ServiceAction action;
    private DIDLLiteWriter didl_writer;
    private DIDLLiteParser didl_parser;
    private Regex title_regex;

    public Cancellable cancellable { get; set; }

    public ItemCreator (ContentDirectory    content_dir,
                        owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
        this.didl_writer = new DIDLLiteWriter (null);
        this.didl_parser = new DIDLLiteParser ();
        try {
            var pattern = "[" + Regex.escape_string (INVALID_CHARS) + "]";
            this.title_regex = new Regex (pattern,
                                          RegexCompileFlags.OPTIMIZE,
                                          RegexMatchFlags.NOTEMPTY);
        } catch (Error error) { } /* ignore */
    }

    public async void run () {
        try {
            this.parse_args ();

            this.didl_parser.item_available.connect ((didl_item) => {
                    this.didl_item = didl_item;
            });

            try {
                this.didl_parser.parse_didl (this.elements);
            } catch (Error parse_err) {
                throw new ContentDirectoryError.BAD_METADATA ("Bad metadata");
            }

            if (this.didl_item == null) {
                var message = _("No items in DIDL-Lite from client: '%s'");

                throw new ItemCreatorError.PARSE (message, this.elements);
            }

            if (didl_item.id == null || didl_item.id != "") {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("@id must be set to \"\" in " +
                                         "CreateItem");
            }

            if ((didl_item.title == null)) {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("dc:title must be set in " +
                                         "CreateItem");
            }

            if ((didl_item.dlna_managed &
                (OCMFlags.UPLOAD |
                 OCMFlags.CREATE_CONTAINER |
                 OCMFlags.UPLOAD_DESTROYABLE)) != 0) {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("Flags that must not be set " +
                                         "were found in 'dlnaManaged'");
            }

            if (didl_item.upnp_class == null ||
                didl_item.upnp_class == "" ||
                !didl_item.upnp_class.has_prefix ("object.item")) {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("Invalid upnp:class given ");
            }

            if (didl_item.restricted) {
                throw new ContentDirectoryError.INVALID_ARGS
                                        ("Cannot create restricted item");
            }

            var container = yield this.fetch_container ();

            /* Verify the create class. Note that we always assume
             * createClass@includeDerived to be false.
             *
             * DLNA_ORG.AnyContainer is a special case. We are allowed to
             * modify the UPnP class to something we support and
             * fetch_container took care of this already.
             */
            if (!container.create_classes.contains (didl_item.upnp_class) &&
                this.container_id != "DLNA_ORG.AnyContainer") {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("Creating of objects with class %s " +
                                         "is not supported in %s",
                                         didl_item.upnp_class,
                                         container.id);
            }

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
                        if (!this.is_profile_valid (info.dlna_profile)) {
                            throw new ContentDirectoryError.BAD_METADATA
                                        ("'%s' DLNA profile unsupported",
                                         info.dlna_profile);
                        }

                        this.item.dlna_profile = info.dlna_profile;
                    }

                    if (info.mime_type != null) {
                        this.item.mime_type = info.mime_type;
                    }
                }

                string sanitized_uri;
                if (this.is_valid_uri (resource.uri, out sanitized_uri)) {
                    this.item.add_uri (sanitized_uri);
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
                this.item.place_holder = true;
            } else {
                var file = File.new_for_uri (this.item.uris[0]);
                this.item.place_holder = !file.is_native ();
            }

            this.item.id = this.item.uris[0];

            yield container.add_item (this.item, this.cancellable);

            yield this.wait_for_item (container);

            this.item.serialize (didl_writer, this.content_dir.http_server);

            // Conclude the successful action
            this.conclude ();

            if (this.container_id == "DLNA.ORG_AnyContainer" &&
                this.item.place_holder) {
                var queue = ItemRemovalQueue.get_default ();

                queue.queue (this.item, this.cancellable);
            }
        } catch (Error err) {
            this.handle_error (err);
        }
    }

    private void parse_args () throws Error {
        /* Start by parsing the 'in' arguments */
        this.action.get ("ContainerID", typeof (string), out this.container_id,
                         "Elements", typeof (string), out this.elements);

        if (this.elements == null) {
            throw new ContentDirectoryError.BAD_METADATA
                                        (_("'Elements' argument missing."));
        } else if (comment_pattern.match_string (this.elements)) {
            throw new ContentDirectoryError.BAD_METADATA
                                        (_("Comments not allowed in XML"));
        }

        if (this.container_id == null) {
            // Sorry we can't do anything without ContainerID
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        }
    }

    private void generalize_upnp_class (ref string upnp_class) {
        char *needle = upnp_class.rstr_len (-1, ".");
        if (needle != null) {
            *needle = '\0';
        }
    }

    private async WritableContainer fetch_container () throws Error {
        MediaObject media_object = null;

        if (this.container_id == "DLNA.ORG_AnyContainer") {
            var upnp_class = didl_item.upnp_class;

            while (upnp_class != "object.item") {
                var expression = new RelationalExpression ();
                expression.op = SearchCriteriaOp.DERIVED_FROM;
                expression.operand1 = "upnp:createClass";
                expression.operand2 = upnp_class;

                uint total_matches;

                var container = this.content_dir.root_container
                                as SearchableContainer;

                if (container != null) {
                    var result = yield container.search (expression,
                                                         0,
                                                         1,
                                                         out total_matches,
                                                         this.cancellable);
                    if (result.size > 0) {
                        media_object = result[0];
                        didl_item.upnp_class = upnp_class;
                        break;
                    } else {
                        this.generalize_upnp_class (ref upnp_class);
                    }
                } else {
                    break;
                }
            }

            if (upnp_class == "object.item") {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("'%s' UPnP class unsupported",
                                         didl_item.upnp_class);
            }
        } else {
            media_object = yield this.content_dir.root_container.find_object
                                        (this.container_id, this.cancellable);
        }

        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        } else if (!(media_object is MediaContainer) ||
                   !(OCMFlags.UPLOAD in media_object.ocm_flags)) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                        media_object.id);
        }

        return media_object as WritableContainer;
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

    private MediaItem create_item (string            id,
                                   WritableContainer parent,
                                   string            title,
                                   string            upnp_class) throws Error {
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
            throw new ContentDirectoryError.BAD_METADATA
                                        ("Creation of item of class '%s' " +
                                         "not supported.",
                                         upnp_class);
        }
    }

    private bool is_valid_uri (string? uri, out string sanitized_uri) {
        sanitized_uri = null;
        if (uri == null || uri == "") {
            return false;
        }

        var soup_uri = new Soup.URI (uri);

        if (soup_uri == null || soup_uri.scheme == null) {
            return false;
        }

        sanitized_uri = soup_uri.to_string (false);

        return true;
    }

    private string mangle_title (string title) throws Error {
        var mangled = title.substring (0, int.min (title.length, 205));
        mangled = this.title_regex.replace_literal (mangled,
                                                    -1,
                                                    0,
                                                    "_",
                                                    RegexMatchFlags.NOTEMPTY);

        return mangled;
    }

    private async string create_uri (WritableContainer container, string title)
                                    throws Error {
        var dir = yield container.get_writable (this.cancellable);
        if (dir == null) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                         container.id);
        }

        var file = dir.get_child_for_display_name (this.mangle_title (title));

        var udn = new uchar[50];
        var id = new uchar[16];

        uuid_generate (id);
        uuid_unparse (id, udn);

        return file.get_uri () + (string) udn;
    }

    private async void wait_for_item (WritableContainer container) {
        debug ("Waiting for new item to appear under container '%s'..",
               container.id);

        MediaItem item = null;

        while (item == null) {
            try {
                item = (yield container.find_object (this.item.id,
                                                     this.cancellable))
                       as MediaItem;
            } catch (Error error) {
                warning ("Error from container '%s' on trying to find newly " +
                         "added child item '%s' in it",
                         container.id,
                         this.item.id);
            }

            if (item == null) {
                var id = container.container_updated.connect ((container) => {
                    this.wait_for_item.callback ();
                });

                uint timeout = 0;
                timeout = Timeout.add_seconds (5, () => {
                    debug ("Timeout on waiting for 'updated' signal on '%s'.",
                           container.id);
                    timeout = 0;
                    this.wait_for_item.callback ();

                    return false;
                });

                yield;

                container.disconnect (id);

                if (timeout != 0) {
                    Source.remove (timeout);
                } else {
                    break;
                }
            }
        }
        debug ("Finished waiting for new item to appear under container '%s'",
               container.id);
    }

    private bool is_profile_valid (string profile) {
        var discoverer = new GUPnP.DLNADiscoverer ((ClockTime) SECOND,
                                                   true,
                                                   false);

        var valid = false;
        foreach (var known_profile in discoverer.list_profiles ()) {
            if (known_profile.name == profile) {
                valid = true;

                break;
            }
        }

        return valid;
    }
}

