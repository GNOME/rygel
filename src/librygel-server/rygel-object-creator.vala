/*
 * Copyright (C) 2010-2011 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *         Jens Georg <jensg@openismus.com>
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

/**
 * Dummy implementation of Rygel.MediaContainer to pass on to
 * Rygel.WritableContianer for creation.
 */
private class Rygel.BaseMediaContainer : MediaContainer {
    /**
     * Create a media container with the specified details.
     *
     * @param id See the id property of the #RygelMediaObject class.
     * @param parent The parent container, if any.
     * @param title See the title property of the #RygelMediaObject class.
     * @param child_count The initially-known number of child items.
     */
    public BaseMediaContainer (string          id,
                               MediaContainer? parent,
                               string          title,
                               int             child_count) {
        Object (id : id,
                parent : parent,
                title : title,
                child_count : child_count);
    }

    /**
     * Fetches the list of media objects directly under this container.
     *
     * @param offset zero-based index of the first item to return
     * @param max_count maximum number of objects to return
     * @param sort_criteria sorting order of objects to return
     * @param cancellable optional cancellable for this operation
     *
     * @return A list of media objects.
     */
    public override async MediaObjects? get_children
                                            (uint         offset,
                                             uint         max_count,
                                             string       sort_criteria,
                                             Cancellable? cancellable)
                                            throws Error {
        return null;
    }

    /**
     * Recursively searches this container for a media object with the given ID.
     *
     * @param id ID of the media object to search for
     * @param cancellable optional cancellable for this operation
     *
     * @return the found media object.
     */
    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        return null;
    }
}



/**
 * CreateObject action implementation.
 */
internal class Rygel.ObjectCreator: GLib.Object, Rygel.StateMachine {
    private static PatternSpec comment_pattern = new PatternSpec ("*<!--*-->*");

    private const string INVALID_CHARS = "/?<>\\:*|\"";

    // In arguments
    private string container_id;
    private string elements;

    private DIDLLiteObject didl_object;
    private MediaObject object;

    private ContentDirectory content_dir;
    private ServiceAction action;
    private Serializer serializer;
    private DIDLLiteParser didl_parser;
    private Regex title_regex;

    public Cancellable cancellable { get; set; }

    public ObjectCreator (ContentDirectory    content_dir,
                          owned ServiceAction action) {
        this.content_dir = content_dir;
        this.cancellable = content_dir.cancellable;
        this.action = (owned) action;
        this.serializer = new Serializer (SerializerType.GENERIC_DIDL);
        this.didl_parser = new DIDLLiteParser ();
        try {
            var pattern = "[" + Regex.escape_string (INVALID_CHARS) + "]";
            this.title_regex = new Regex (pattern,
                                          RegexCompileFlags.OPTIMIZE,
                                          RegexMatchFlags.NOTEMPTY);
        } catch (Error error) { assert_not_reached (); }
    }

    public async void run () {
        try {
            this.parse_args ();
            this.parse_didl ();

            var container = yield this.fetch_container ();

            /* Verify the create class. Note that we always assume
             * createClass@includeDerived to be false.
             *
             * DLNA.ORG_AnyContainer is a special case. We are allowed to
             * modify the UPnP class to something we support and
             * fetch_container took care of this already.
             */
            if (!container.can_create (this.didl_object.upnp_class) &&
                this.container_id != MediaContainer.ANY) {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("Creating of objects with class %s " +
                                         "is not supported in %s",
                                         this.didl_object.upnp_class,
                                         container.id);
            }

            if (this.didl_object is DIDLLiteContainer &&
                !this.validate_create_class (container)) {
                throw new ContentDirectoryError.BAD_METADATA
                                   (_("upnp:createClass value not supported"));
            }

            yield this.create_object_from_didl (container);
            if (this.object is MediaFileItem) {
                yield container.add_item (this.object as MediaFileItem,
                                          this.cancellable);
            } else {
                yield container.add_container (this.object as MediaContainer,
                                               this.cancellable);
            }

            yield this.wait_for_object (container);

            this.object.serialize (serializer, this.content_dir.http_server);

            // Conclude the successful action
            this.conclude ();

            if (this.container_id == MediaContainer.ANY &&
                (this.object is MediaFileItem &&
                 (this.object as MediaFileItem).place_holder)) {
                var queue = ObjectRemovalQueue.get_default ();

                queue.queue (this.object, this.cancellable);
            }
        } catch (Error err) {
            this.handle_error (err);
        }
    }

    /**
     * Check the supplied input parameters.
     */
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
            throw new ContentDirectoryError.INVALID_ARGS
                                        (_("Missing ContainerID argument"));
        }
    }

    /**
     * Parse the given DIDL-Lite snippet.
     *
     * Parses the DIDL-Lite and performs checking of the passed meta-data
     * according to UPnP and DLNA guidelines.
     */
    private void parse_didl () throws Error {
        // FIXME: This will take the last object in the DIDL-Lite, maybe we
        // should limit it to one somehow.
        this.didl_parser.object_available.connect ((didl_object) => {
            this.didl_object = didl_object;
        });

        try {
            this.didl_parser.parse_didl (this.elements);
        } catch (Error parse_err) {
            throw new ContentDirectoryError.BAD_METADATA ("Bad metadata");
        }

        if (this.didl_object == null) {
            var message = _("No objects in DIDL-Lite from client: '%s'");

            throw new ContentDirectoryError.BAD_METADATA
                                        (message, this.elements);
        }

        if (didl_object.id == null || didl_object.id != "") {
            var msg = _("@id must be set to \"\" in CreateObject call");
            throw new ContentDirectoryError.BAD_METADATA (msg);
        }

        if (didl_object.title == null) {
            var msg = _("dc:title must not be empty in CreateObject call");
            throw new ContentDirectoryError.BAD_METADATA (msg);
        }

        // FIXME: Is this check really necessary? 7.3.118.4 passes without it.
        // These flags must not be set on items.
        if (didl_object is DIDLLiteItem &&
            ((didl_object.dlna_managed &
             (OCMFlags.UPLOAD |
              OCMFlags.CREATE_CONTAINER |
              OCMFlags.UPLOAD_DESTROYABLE)) != 0)) {
            var msg =  _("Flags that must not be set were found in 'dlnaManaged'");
            throw new ContentDirectoryError.BAD_METADATA (msg);
        }

        if (didl_object.upnp_class == null ||
            didl_object.upnp_class == "" ||
            !didl_object.upnp_class.has_prefix ("object")) {
            throw new ContentDirectoryError.BAD_METADATA
                                        (_("Invalid upnp:class given in CreateObject"));
        }

        if (didl_object.restricted) {
            throw new ContentDirectoryError.BAD_METADATA
                                        (_("Cannot create restricted item"));
        }

        // Handle DIDL_S items...
        if (this.didl_object.upnp_class == "object.item") {
            var resources = this.didl_object.get_resources ();
            if (resources != null &&
                resources.data.protocol_info.dlna_profile == "DIDL_S") {
                this.didl_object.upnp_class = PlaylistItem.UPNP_CLASS;
            }
        }
    }

    /**
     * Modify the give UPnP class to be a more general one.
     *
     * Used to simplify the search for a valid container in the
     * DLNA.ORG_AnyContainer use-case.
     * Example: object.item.videoItem.videoBroadcast → object.item.videoItem
     *
     * @param upnp_class the current UPnP class which will be modified in-place.
     */
    private void generalize_upnp_class (ref string upnp_class) {
        char *needle = upnp_class.rstr_len (-1, ".");
        if (needle != null) {
            *needle = '\0';
        }
    }

    private async SearchExpression build_create_class_expression
                                        (SearchExpression expression) {
        // Take create-classes into account
        if (!(this.didl_object is DIDLLiteContainer)) {
            return expression;
        }

        var didl_container = this.didl_object as DIDLLiteContainer;
        var create_classes = didl_container.get_create_classes ();
        if (create_classes == null) {
            return expression;
        }

        var builder = new StringBuilder ("(");
        foreach (var create_class in create_classes) {
            builder.append_printf ("(upnp:createClass derivedfrom \"%s\") AND",
                                   create_class);
        }

        // remove dangeling AND
        builder.truncate (builder.len - 3);
        builder.append (")");

        try {
            var parser = new Rygel.SearchCriteriaParser (builder.str);
            yield parser.run ();

            var rel = new LogicalExpression ();
            rel.operand1 = expression;
            rel.op = LogicalOperator.AND;
            rel.operand2 = parser.expression;

            return rel;
        } catch (Error error) {
            assert_not_reached ();
        }
    }

    /**
     * Find a container that can create items matching the UPnP class of the
     * requested item.
     *
     * If the item's UPnP class cannot be found, generalize the UPnP class until
     * we reach object.item according to DLNA guideline 7.3.120.4.
     *
     * @returns a container able to create the item or null if no such container
     *          can be found.
     */
    private async MediaObject? find_any_container () throws Error {
        var root_container = this.content_dir.root_container
                                        as SearchableContainer;

        if (root_container == null) {
            return null;
        }

        var upnp_class = this.didl_object.upnp_class;

        var expression = new RelationalExpression ();
        expression.op = SearchCriteriaOp.DERIVED_FROM;
        expression.operand1 = "upnp:createClass";

        // Add container's create classes to the search expression if there
        // are some
        var search_expression = yield this.build_create_class_expression
                                        (expression);

        while (upnp_class != "object") {
            expression.operand2 = upnp_class;

            uint total_matches;
            var result = yield root_container.search (search_expression,
                                                      0,
                                                      1,
                                                      out total_matches,
                                                      root_container.sort_criteria,
                                                      this.cancellable);
            if (result.size > 0) {
                this.didl_object.upnp_class = upnp_class;

                return result[0];
            } else {
                this.generalize_upnp_class (ref upnp_class);
            }
        }

        if (upnp_class == "object") {
            throw new ContentDirectoryError.BAD_METADATA
                                    (_("UPnP class '%s' not supported"),
                                     this.didl_object.upnp_class);
        }

        return null;
    }

    /**
     * Get the container to create the item in.
     *
     * This will either try to fetch the container supplied by the caller or
     * search for a container if the caller supplied the "DLNA.ORG_AnyContainer"
     * id.
     *
     * @return an instance of WritableContainer matching the criteria
     * @throws ContentDirectoryError for various problems
     */
    private async WritableContainer fetch_container () throws Error {
        MediaObject media_object = null;

        if (this.container_id == MediaContainer.ANY) {
            media_object = yield this.find_any_container ();
        } else {
            media_object = yield this.content_dir.root_container.find_object
                                        (this.container_id, this.cancellable);
        }

        if (media_object == null || !(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_CONTAINER
                                        (_("No such container"));
        }

        if (!(media_object is WritableContainer)) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                         media_object.id);
        }

        // If the object to be created is an item, ocm_flags must contain
        // OCMFlags.UPLOAD, it it's a container, ocm_flags must contain
        // OCMFlags.CREATE_CONTAINER
        if (!((this.didl_object is DIDLLiteItem &&
            (OCMFlags.UPLOAD in media_object.ocm_flags)) ||
           (this.didl_object is DIDLLiteContainer &&
            (OCMFlags.CREATE_CONTAINER in media_object.ocm_flags)))) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                         media_object.id);
        }

        // FIXME: Check for @restricted=1 missing?

        return media_object as WritableContainer;
    }

    private void conclude () {
        /* Retrieve generated string */
        string didl = this.serializer.get_string ();

        /* Set action return arguments */
        this.action.set ("ObjectID", typeof (string), this.object.id,
                         "Result", typeof (string), didl);

        this.action.return ();
        this.completed ();
    }

    private bool validate_create_class (WritableContainer container) {
        var didl_cont = this.didl_object as DIDLLiteContainer;
        var create_classes = didl_cont.get_create_classes ();

        if (create_classes == null) {
            return true;
        }

        foreach (var create_class in create_classes) {
            if (!container.can_create (create_class)) {
                return false;
            }
        }

        return true;
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
        if (!(this.object is MediaFileItem)) {
            return "";
        }

        var item = this.object as MediaFileItem;

        if (item is ImageItem) {
            return "image";
        } else if (item is VideoItem) {
            return "video";
        } else {
            return "audio";
        }
    }

    /**
     * Transfer information passed by caller to a MediaObject.
     *
     * WritableContainer works on MediaObject so we transfer the supplied data
     * to one. Additionally some checks are performed (e.g. whether the DLNA
     * profile is supported or not) or sanitize the supplied title for use as
     * part of the on-disk filename.
     *
     * This function fills ObjectCreator.object.
     */
    private async void create_object_from_didl (WritableContainer container)
                                                throws Error {
        this.object = this.create_object (this.didl_object.id,
                                          container,
                                          this.didl_object.title,
                                          this.didl_object.upnp_class);

        this.object.apply_didl_lite (this.didl_object);

        if (this.object is MediaItem) {
            this.extract_item_parameters ();
        }

        // extract_item_parameters could not find an uri
        if (this.object.get_uris ().is_empty) {
            var uri = yield this.create_uri (container, this.object.title);
            this.object.add_uri (uri);
            if (this.object is MediaFileItem) {
                (this.object as MediaFileItem).place_holder = true;
            }
        } else {
            if (this.object is MediaFileItem) {
                var file = File.new_for_uri (this.object.get_primary_uri ());
                (this.object as MediaFileItem).place_holder = !file.is_native ();
            }
        }

        this.object.id = this.object.get_primary_uri ();

        this.parse_and_verify_didl_date ();
    }

    private void extract_item_parameters () throws Error {
        var item = this.object as MediaFileItem;

        foreach (var resource in this.didl_object.get_resources ()) {
            var info = resource.protocol_info;

            if (info != null) {
                if (info.dlna_profile != null) {
                    if (!this.is_profile_valid (info.dlna_profile)) {
                        var msg = _("DLNA profile '%s' not supported");
                        throw new ContentDirectoryError.BAD_METADATA
                                    (msg,
                                     info.dlna_profile);
                    }

                    item.dlna_profile = info.dlna_profile;
                }

                if (info.mime_type != null) {
                    item.mime_type = info.mime_type;
                }
            }

            string sanitized_uri = null;
            if (this.is_valid_uri (resource.uri, out sanitized_uri)) {
                item.add_uri (sanitized_uri);
            }

            if (resource.size >= 0) {
                item.size = resource.size;
            }
        }

        if (item.mime_type == null) {
            item.mime_type = this.get_generic_mime_type ();
        }

        if (item.size < 0) {
            item.size = 0;
        }
    }

    private void parse_and_verify_didl_date () throws Error {
        if (!(this.didl_object is DIDLLiteItem)) {
            return;
        }

        var didl_item = this.didl_object as DIDLLiteItem;
        if (didl_item.date == null) {
            return;
        }

        var parsed_date = new Soup.Date.from_string (didl_item.date);
        if (parsed_date != null) {
            (this.object as MediaFileItem).date = parsed_date.to_string
                                            (Soup.DateFormat.ISO8601);

            return;
        }

        int year = 0, month = 0, day = 0;

        if (didl_item.date.scanf ("%4d-%02d-%02d",
                                  out year,
                                  out month,
                                  out day) != 3) {
            throw new ContentDirectoryError.BAD_METADATA
                                    (_("Invalid date format: %s"),
                                     didl_item.date);
        }

        var date = GLib.Date ();
        date.set_dmy ((DateDay) day, (DateMonth) month, (DateYear) year);

        if (!date.valid ()) {
            throw new ContentDirectoryError.BAD_METADATA
                                    (_("Invalid date: %s"),
                                     didl_item.date);
        }

        (this.object as MediaFileItem).date = didl_item.date + "T00:00:00";
    }

    private MediaObject create_object (string            id,
                                       WritableContainer parent,
                                       string            title,
                                       string            upnp_class)
                                       throws Error {
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
        case PlaylistItem.UPNP_CLASS:
            return new PlaylistItem (id, parent, title);
        case MediaContainer.UPNP_CLASS:
        case MediaContainer.STORAGE_FOLDER:
            return new BaseMediaContainer (id, parent, title, 0);
        case MediaContainer.PLAYLIST:
            var container = new BaseMediaContainer (id, parent, title, 0);
            container.upnp_class = upnp_class;
            return container;
        default:
            var msg = _("Cannot create object of class '%s': Not supported");
            throw new ContentDirectoryError.BAD_METADATA (msg, upnp_class);
        }
    }

    /**
     * Simple check for the validity of an URI.
     *
     * Check is done by parsing the URI with soup. Additionaly a cleaned-up
     * version of the URI is returned in sanitized_uri.
     *
     * @param uri the input URI
     * @param sanitized_uri containes a sanitized version of the URI on return
     * @returns true if the URI is valid, false otherwise.
     */
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

    /**
     * Transform the title to be usable on legacy file-systems such as FAT32.
     *
     * The function trims down the title to 205 chars (leaving room for an UUID)
     * and replaces all special characters.
     *
     * @param title of the the media item
     * @return the cleaned and shortened title
     */
    private string mangle_title (string title) throws Error {
        var mangled = title.substring (0, int.min (title.length, 205));
        mangled = this.title_regex.replace_literal (mangled,
                                                    -1,
                                                    0,
                                                    "_",
                                                    RegexMatchFlags.NOTEMPTY);

        return UUID.get () + "-" + mangled;
    }

    /**
     * Create an URI from the item's title.
     *
     * Create an unique URI from the supplied title by cleaning it from
     * unwanted characters, shortening it and adding an UUID.
     *
     * @param container to create the item in
     * @param title of the item to base the name on
     * @returns an URI for the newly created item
     */
    private async string create_uri (WritableContainer container, string title)
                                    throws Error {
        var dir = yield container.get_writable (this.cancellable);
        if (dir == null) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                         container.id);
        }

        var file = dir.get_child_for_display_name (this.mangle_title (title));

        return file.get_uri ();
    }

    /**
     * Wait for the new object
     *
     * When creating an object in the back-end via WritableContainer.add_item
     * or WritableContainer.add_container there might be a delay between the
     * creation and the back-end having the newly created item available. This
     * function waits for the item to become available by hooking into the
     * container_updated signal. The maximum time to wait is 5 seconds.
     *
     * @param container to watch
     */
    private async void wait_for_object (WritableContainer container) {
        debug ("Waiting for new object to appear under container '%s'…",
               container.id);

        MediaObject object = null;

        while (object == null) {
            try {
                object = yield container.find_object (this.object.id,
                                                      this.cancellable);
            } catch (Error error) {
                var msg = _("Error from container '%s' on trying to find the newly added child object '%s' in it: %s");
                warning (msg, container.id, this.object.id, error.message);
            }

            if (object == null) {
                var id = container.container_updated.connect ((container) => {
                    this.wait_for_object.callback ();
                });

                uint timeout = 0;
                timeout = Timeout.add_seconds (5, () => {
                    debug ("Timeout on waiting for 'updated' signal on '%s'.",
                           container.id);
                    timeout = 0;
                    this.wait_for_object.callback ();

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
        debug ("Finished waiting for new object to appear under container '%s'",
               container.id);

        this.object = object;
    }

    /**
     * Check if the profile is supported.
     *
     * The check is performed against the MediaEngine's database explicitly excluding
     * the transcoders.
     *
     * @param profile to check
     * @returns true if the profile is supported, false otherwise.
     */
    private bool is_profile_valid (string profile) {
        unowned GLib.List<DLNAProfile> profiles, result;

        var plugin = this.content_dir.root_device.resource_factory as MediaServerPlugin;
        profiles = plugin.upload_profiles;
        var p = new DLNAProfile (profile, "");

        result = profiles.find_custom (p, DLNAProfile.compare_by_name);

        return result != null;
    }
}
