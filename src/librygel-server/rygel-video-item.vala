/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Craig Pratt <craig@ecaspia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

using GUPnP;
using Gee;

/**
 * Represents a video item.
 */
public class Rygel.VideoItem : AudioItem, VisualItem {
    public new const string UPNP_CLASS = "object.item.videoItem";

    public string author { get; set; }

    //TODO: This property documentation is not used.
    //See valadoc bug: https://bugzilla.gnome.org/show_bug.cgi?id=684367

    /**
     * The width of the item source content (this.uri) in pixels
     * A value of -1 means that the width is unknown
     */
    public int width { get; set; default = -1; }

    /**
     * The height of the item source content (this.uri) in pixels
     * A value of -1 means that the height is unknown
     */
    public int height { get; set; default = -1; }

    /**
     * The number of bits per pixel in the source video resource (this.uri)
     * A value of -1 means that the color depth is unknown
     */
    public int color_depth { get; set; default = -1; }

    /**
     * Thumbnail pictures to represent the video.
     */
    public ArrayList<Thumbnail> thumbnails { get; protected set; }

    public ArrayList<Subtitle> subtitles { get; protected set; }

    public VideoItem (string         id,
                      MediaContainer parent,
                      string         title,
                      string         upnp_class = VideoItem.UPNP_CLASS) {
        Object (id : id,
                parent : parent,
                title : title,
                upnp_class : upnp_class);
    }

    public override void constructed () {
        base.constructed ();

        this.thumbnails = new ArrayList<Thumbnail> ();
        this.subtitles = new ArrayList<Subtitle> ();
    }

    public override void add_uri (string uri) {
        base.add_uri (uri);

        this.add_thumbnail_for_uri (uri);

        var subtitle_manager = SubtitleManager.get_default ();

        if (subtitle_manager != null) {
            try {
                var subtitles = subtitle_manager.get_subtitles (uri);
                this.subtitles.add_all (subtitles);
            } catch (Error err) {}
        }
    }

    internal override MediaResource get_primary_resource () {
        var res = base.get_primary_resource ();

        this.set_visual_resource_properties (res);

        return res;
    }

    internal override int compare_by_property (MediaObject media_object,
                                               string      property) {
        if (!(media_object is VideoItem)) {
           return 1;
        }

        var item = media_object as VideoItem;

        switch (property) {
        case "upnp:author":
            return this.compare_string_props (this.author, item.author);
        default:
            return base.compare_by_property (item, property);
        }
    }

    private string get_first (GLib.List<DIDLLiteContributor>? contributors) {
        if (contributors != null) {
            return contributors.data.name;
        }

        return "";
    }

    internal override void apply_didl_lite (DIDLLiteObject didl_object) {
        base.apply_didl_lite (didl_object);

        this.author = this.get_first (didl_object.get_authors ());
    }

    internal override DIDLLiteObject? serialize (Serializer serializer,
                                                 HTTPServer  http_server)
                                                 throws Error {
        var didl_item = base.serialize (serializer, http_server) as DIDLLiteItem;

        if (this.author != null && this.author != "") {
            var contributor = didl_item.add_author ();
            contributor.name = this.author;
        }

        if (!this.place_holder) {
            var main_subtitle = null as Subtitle;
            foreach (var subtitle in this.subtitles) {
                string protocol;
                try {
                    protocol = this.get_protocol_for_uri (subtitle.uri);
                } catch (Error e) {
                    message (/*_*/("Could not determine protocol for URI %s"),
                             subtitle.uri);

                    continue;
                }

                if (http_server.need_proxy (subtitle.uri)) {
                    var uri = subtitle.uri; // Save the original URI
                    var index = this.subtitles.index_of (subtitle);

                    subtitle.uri = http_server.create_uri_for_object (this,
                                                                      -1,
                                                                      index,
                                                                      null);
                    subtitle.add_didl_node (didl_item);

                    if (main_subtitle == null) {
                        main_subtitle = new Subtitle (subtitle.mime_type,
                                                      subtitle.caption_type);
                        main_subtitle.uri = subtitle.uri;
                    }
                    subtitle.uri = uri; // Now restore the original URI
                } else if (main_subtitle == null) {
                    main_subtitle = subtitle;
                }

                if (http_server.is_local () || protocol != "internal") {
                    subtitle.add_didl_node (didl_item);
                }
            }

            if (main_subtitle != null) {
                // Add resource-level subtitle metadata to all streamable
                // video resources Note: All resources have already been
                // serialized by the base

                // Work-around bgo#753382 - add subtitle to all resources
                var resources = didl_item.get_resources ();
                foreach (var resource in resources) {
                    // Don't add subtitles to subtitles
                    if (resource.protocol_info.mime_type == main_subtitle.mime_type) {
                        continue;
                    }

                    resource.subtitle_file_type =
                        main_subtitle.caption_type.up ();
                    resource.subtitle_file_uri = main_subtitle.uri;
                }
            }

            // Also add upnp:albumArtURI for thumbnails. Some players need this apparently
            // even for videos instead of using the JPEG_TN/PNG_TN resource
            if (this.thumbnails.size != 0) {
                var protocol = this.get_protocol_for_uri (this.thumbnails[0].uri);
                if (http_server.is_local () || protocol != "internal") {
                    didl_item.album_art = this.thumbnails[0].uri;
                } else {
                    // Create a http uri for the album art that our server can process
                    string http_uri = http_server.create_uri_for_object (this,
                            0,
                            -1,
                            null);
                    didl_item.album_art = MediaFileItem.address_regex.replace_literal
                        (http_uri,
                         -1,
                         0,
                         http_server.context.address.to_string ());
                }
            }
        }

        return didl_item;
    }

    internal virtual void add_subtitle_resources (HTTPServer http_server) {
        if (this.place_holder) {
            return;
        }

        for (var i = 0; i < this.subtitles.size; i++) {
            var subtitle = this.subtitles.get (i);
            // Add the defined thumbnail uri unconditionally
            //  (it will be filtered out if the request is remote)
            string protocol;
            try {
                protocol = this.get_protocol_for_uri (subtitle.uri);
            } catch (Error e) {
                message (_("Could not determine protocol for URI %s"),
                         subtitle.uri);

                continue;
            }

            var subtitle_resource = subtitle.get_resource (protocol, i);
            subtitle_resource.uri = subtitle.uri;
            this.get_resource_list ().add (subtitle_resource);
            if (http_server.need_proxy (subtitle.uri)) {
                var http_sub_res = subtitle.get_resource
                                    (http_server.get_protocol (), i);

                // Make a http uri for the thumbnail
                http_sub_res.uri = http_server.create_uri_for_object
                                             (this,
                                              -1,
                                              i,
                                              null);
                this.get_resource_list ().add (http_sub_res);
            }
        }
    }

    internal override void add_additional_resources (HTTPServer server) {
        base.add_additional_resources (server);

        this.add_thumbnail_resources (server);
        this.add_subtitle_resources (server);
    }
}
