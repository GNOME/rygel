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
 * CreateObject action implementation.
 */
internal class Rygel.ItemCreator: GLib.Object, Rygel.StateMachine {
    private static PatternSpec comment_pattern = new PatternSpec ("*<!--*-->*");

    private const string INVALID_CHARS = "/?<>\\:*|\"";

    // In arguments
    private string container_id;
    private string elements;

    private DIDLLiteItem didl_item;
    private MediaItem item;

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
             * DLNA_ORG.AnyContainer is a special case. We are allowed to
             * modify the UPnP class to something we support and
             * fetch_container took care of this already.
             */
            if (!container.can_create (this.didl_item.upnp_class) &&
                this.container_id != "DLNA_ORG.AnyContainer") {
                throw new ContentDirectoryError.BAD_METADATA
                                        ("Creating of objects with class %s " +
                                         "is not supported in %s",
                                         this.didl_item.upnp_class,
                                         container.id);
            }

            yield this.create_item_from_didl (container);
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
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        }
    }

    /**
     * Parse the given DIDL-Lite snippet.
     *
     * Parses the DIDL-Lite and performs checking of the passed meta-data
     * according to UPnP and DLNA guidelines.
     */
    private void parse_didl () throws Error {
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

            throw new ContentDirectoryError.BAD_METADATA
                                        (message, this.elements);
        }

        if (didl_item.id == null || didl_item.id != "") {
            throw new ContentDirectoryError.BAD_METADATA
                                        ("@id must be set to \"\" in " +
                                         "CreateItem");
        }

        if (didl_item.title == null) {
            throw new ContentDirectoryError.BAD_METADATA
                                    ("dc:title must be set in " +
                                     "CreateItem");
        }

        // FIXME: Is this check really necessary? 7.3.118.4 passes without it.
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

        var upnp_class = this.didl_item.upnp_class;

        var expression = new RelationalExpression ();
        expression.op = SearchCriteriaOp.DERIVED_FROM;
        expression.operand1 = "upnp:createClass";

        while (upnp_class != "object.item") {
            expression.operand2 = upnp_class;

            uint total_matches;
            var result = yield root_container.search (expression,
                                                      0,
                                                      1,
                                                      out total_matches,
                                                      root_container.sort_criteria,
                                                      this.cancellable);
            if (result.size > 0) {
                this.didl_item.upnp_class = upnp_class;

                return result[0];
            } else {
                this.generalize_upnp_class (ref upnp_class);
            }
        }

        if (upnp_class == "object.item") {
            throw new ContentDirectoryError.BAD_METADATA
                                    ("'%s' UPnP class unsupported",
                                     this.didl_item.upnp_class);
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
     * @return a instance of WritableContainer matching the criteria
     * @throws ContentDirectoryError for various problems
     */
    private async WritableContainer fetch_container () throws Error {
        MediaObject media_object = null;

        if (this.container_id == "DLNA.ORG_AnyContainer") {
            media_object = yield this.find_any_container ();
        } else {
            media_object = yield this.content_dir.root_container.find_object
                                        (this.container_id, this.cancellable);
        }

        if (media_object == null || !(media_object is MediaContainer)) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT
                                        (_("No such object"));
        } else if (!(OCMFlags.UPLOAD in media_object.ocm_flags) ||
                   !(media_object is WritableContainer)) {
            throw new ContentDirectoryError.RESTRICTED_PARENT
                                        (_("Object creation in %s not allowed"),
                                         media_object.id);
        }

        // FIXME: Check for @restricted=1 missing?

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

    /**
     * Transfer information passed by caller to a MediaItem.
     *
     * WritableContainer works on MediaItem so we transfer the supplied data to
     * one. Additionally some checks are performed (e.g. whether the DLNA
     * profile is supported or not) or sanitize the supplied title for use as
     * part of the on-disk filename.
     *
     * This function fills ItemCreator.item.
     */
    private async void create_item_from_didl (WritableContainer container)
                                                   throws Error {
        this.item = this.create_item (this.didl_item.id,
                                      container,
                                      this.didl_item.title,
                                      this.didl_item.upnp_class);

        var resources = this.didl_item.get_resources ();
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

        this.parse_and_verify_didl_date ();
    }

    private void parse_and_verify_didl_date () throws Error {
        if (this.didl_item.date == null) {
            return;
        }

        var parsed_date = new Soup.Date.from_string (this.didl_item.date);
        if (parsed_date != null) {
            this.item.date = parsed_date.to_string (Soup.DateFormat.ISO8601);

            return;
        }

        int year = 0, month = 0, day = 0;

        if (this.didl_item.date.scanf ("%4d-%02d-%02d",
                                       out year,
                                       out month,
                                       out day) != 3) {
            throw new ContentDirectoryError.BAD_METADATA
                                    ("Invalid date format: %s",
                                     this.didl_item.date);
        }

        var date = GLib.Date ();
        date.set_dmy ((DateDay) day, (DateMonth) month, (DateYear) year);

        if (!date.valid ()) {
            throw new ContentDirectoryError.BAD_METADATA
                                    ("Invalid date: %s",
                                     this.didl_item.date);
        }

        this.item.date = this.didl_item.date + "T00:00:00";
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

        var udn = new uchar[50];
        var id = new uchar[16];

        UUID.generate (id);
        UUID.unparse (id, udn);

        return (string) udn + "-" + mangled;
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
     * Wait for the new item
     *
     * When creating an item in the back-end via WritableContainer.add_item
     * there might be a delay between the creation and the back-end having the
     * newly created item available. This function waits for the item to become
     * available by hooking into the container_updated signal. The maximum time
     * to wait is 5 seconds.
     *
     * @param container to watch
     */
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

        profiles = MediaEngine.get_default ().get_dlna_profiles ();
        var p = new DLNAProfile (profile, "");

        result = profiles.find_custom (p, DLNAProfile.compare_by_name);

        return result != null;
    }
}
