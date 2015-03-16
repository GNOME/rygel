/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Doug Galligan <doug@sentosatech.com>
 *         Craig Pratt <craig@ecaspia.com>
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

private errordomain Rygel.MediaFileItemError {
    BAD_URI
}

/**
 * Represents a file-accessible or http-accessible media item (music file,
 * image file, video file, etc) with some pre-established metadata or a
 * content placeholder for uploaded content.
 *
 * Items representing non-file-accessible content should create their own
 * MediaItem subclass.
 */
public abstract class Rygel.MediaFileItem : MediaItem {
    /**
     * The mime type of the source content (this.uri).
     * A null/empty value means that the mime-type is unknown
     */
    public string mime_type { get; set; }

    /**
     * The DLNA profile of the source content (this.uri).
     * A null/empty value means that the DLNA profile is unknown
     */
    public string dlna_profile { get; set; }

    /**
     * The size of the source content (this.uri).
     * A value of -1 means that the size is unknown
     */
    private int64 _size = -1;
    public int64 size {
        get {
            return this._size;
        }

        set {
            if (value == 0) {
                this.place_holder = true;
            }

            this._size = value;
        }
    }   // Size in bytes

    public bool place_holder { get; set; default = false; }

    public override OCMFlags ocm_flags {
        get {
            var flags = OCMFlags.NONE;

            if (this.place_holder) {
                // Place-holder items are always destroyable.
                flags |= OCMFlags.DESTROYABLE;
            } else {
                var config = MetaConfig.get_default ();
                var allow_deletion = true;

                try {
                    allow_deletion = config.get_allow_deletion ();
                } catch (Error error) {}

                if (allow_deletion) {
                    flags |= OCMFlags.DESTROYABLE;
                }
            }

            if (this is UpdatableObject) {
                flags |= OCMFlags.CHANGE_METADATA;
            }

            return flags;
        }
    }

    protected static Regex address_regex;

    public MediaFileItem (string         id,
                          MediaContainer parent,
                          string         title,
                          string         upnp_class) {
        Object (id : id,
                parent : parent,
                title : title,
                upnp_class : upnp_class);
    }

    public static Gee.HashMap<string, string> mime_to_ext;

    static construct {
        try {
            address_regex = new Regex (Regex.escape_string ("@ADDRESS@"));
        } catch (GLib.RegexError err) {
            assert_not_reached ();
        }
    }

    public override DataSource? create_stream_source_for_resource
                                        (HTTPRequest request,
                                         MediaResource resource)
                                         throws Error {
        return MediaEngine.get_default ().create_data_source_for_resource
                                        (this, resource);
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer http_server)
                                                 throws Error {
        var didl_item = base.serialize (serializer, http_server) as DIDLLiteItem;

        if (!this.place_holder) {
            // Subclasses can override add_resources and augment the media
            // resource list (which should contain the primary resource
            // representations for the MediaItem at this point) with any
            // secondary representations or alternate delivery mechanisms they
            // can provide
            this.add_additional_resources (http_server);
        }
        this.serialize_resource_list (didl_item, http_server);

        return didl_item;
    }

    /**
     * Subclasses override this method to create the type-specific primary
     * MediaResource.
     *
     * The resource returned is presumed to represent the "internal" file
     * resource and a uri referring to the source file. Transport-specific
     * variants can be created by the caller.
     *
     * @return a RygelMediaResource for the on-disk file represented by this
     * instance.
     */
    public virtual MediaResource get_primary_resource () {
        var res = new MediaResource ("primary");

        res.mime_type = this.mime_type;
        res.dlna_profile = this.dlna_profile;
        res.dlna_flags = DLNAFlags.BACKGROUND_TRANSFER_MODE;

        // MediaFileItems refer directly to the source URI
        res.uri = this.get_primary_uri ();
        try {
            res.protocol = this.get_protocol_for_uri (res.uri);
        } catch (Error e) {
            warning (_("Could not determine protocol for uri %s"),
                     res.uri);
        }

        res.extension = this.get_extension ();
        res.size = this.size;

        return res;
    }

    /**
     * Return the file/uri extension that best represents the item's primary
     * resource.
     */
    public virtual string get_extension () {
        string uri_extension = null;
        // Use the extension from the source content filename, if it has an
        // extension
        string basename = Path.get_basename (this.get_primary_uri ());
        int dot_index = -1;
        if (basename != null) {
            dot_index = basename.last_index_of (".");
            if (dot_index > -1) {
               uri_extension = basename.substring (dot_index + 1);
            }
        }

        if (uri_extension == null) {
            uri_extension = ext_from_mime_type (this.mime_type);
        }

        return uri_extension;
    }

    protected string ext_from_mime_type (string mime_type) {
        if (mime_to_ext == null) {
            // Lazy initialization of the static hashmap
            mime_to_ext = new Gee.HashMap<string, string> ();
            // videos
            string[] videos = {"mpeg", "webm", "ogg", "mp4"};

            foreach (string video in videos) {
                mime_to_ext.set ("video/" + video, video);
            }
            mime_to_ext.set ("video/x-matroska", "mkv");

            // audios
            mime_to_ext.set ("audio/x-wav", "wav");
            mime_to_ext.set ("audio/x-matroska", "mka");
            mime_to_ext.set ("audio/L16","pcm");
            mime_to_ext.set ("audio/vnd.dlna.adts","adts");
            mime_to_ext.set ("audio/mpeg","mp3");
            mime_to_ext.set ("audio/3gpp","3gp");

            // images
            string[] images = {"jpeg", "png"};

            foreach (string image in images) {
                mime_to_ext.set ("image/" + image, image);
            }

            // texts
            mime_to_ext.set ("text/srt", "srt");
            mime_to_ext.set ("text/xml", "xml");

            // applications? (can be either video or audio?);
            mime_to_ext.set ("application/ogg", "ogg");
        }

        if (MediaFileItem.mime_to_ext.has_key (mime_type)) {
            return mime_to_ext.get (mime_type);
        }

        return "";
    }


    /**
     * Subclasses can override this method to augment the MediaObject MediaResource
     * list with secondary MediaResource objects representing derivative resources.
     *
     * Note: Implementations should add both internal/file-based resources and HTTP-accessible
     *       resources to the MediaResource list.
     * FIXME: Will be renamed once we can safely remove old add_resources
     */
    internal virtual void add_additional_resources (HTTPServer server) {
        /* Do nothing - provide default implementation to avoid unnecessary
           empty code blocks.
         */
    }
}
