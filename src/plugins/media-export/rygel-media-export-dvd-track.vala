/*
 * Copyright (C) 2015 Jens Georg <mail@jensge.org>
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.MediaExport.DVDTrack : VideoItem {
    public new const string UPNP_CLASS = Rygel.VideoItem.UPNP_CLASS + ".dvdTrack";

    public Xml.Node* node { private get; construct set; }
    public int track { private get; construct set; }

    public DVDTrack (string         id,
                     MediaContainer parent,
                     string         title,
                     int            track,
                     Xml.Node*      node) {
        Object (id : id,
                parent : parent,
                node : node,
                title : title,
                track : track,
                upnp_class : Rygel.VideoItem.UPNP_CLASS);
    }

    public override void constructed () {
        base.constructed ();

        // If we are created with a null node, then we are created from the
        // database and all the information is already there.
        if (this.node != null) {
            GLib.Uri uri;
            try {
                uri = GLib.Uri.parse (this.parent.get_primary_uri (), UriFlags.NONE);
            } catch (Error error) {
                assert_not_reached ();
            }
            uri = Soup.uri_copy (uri,
                                 Soup.URIComponent.SCHEME, "dvd",
                                 Soup.URIComponent.QUERY, "title=%d".printf (track + 1),
                                 Soup.URIComponent.NONE);

            this.add_uri (uri.to_string ());

            this.dlna_profile = "MPEG_PS";
            this.mime_type = "video/mpeg";

            var it = node->children;
            while (it != null) {
                if (it->name == "length") {
                    this.duration = (int) double.parse (it->children->content);
                } else if (it->name == "width") {
                    this.width = int.parse (it->children->content);
                } else if (it->name == "height") {
                    this.height = int.parse (it->children->content);
                } else if (it->name == "format") {
                    this.dlna_profile += "_" + it->children->content;
                }
                // TODO: Japanese formats...
                it = it->next;
            }

            var media_engine = MediaEngine.get_default ();
            media_engine.get_resources_for_item.begin (this,
                                                       (obj, res) => {
                var added_resources = media_engine
                                            .get_resources_for_item.end (res);
                debug ("Adding %d resources to this source %s",
                       added_resources.size,
                       this.get_primary_uri ());
                this.get_resource_list ().add_all (added_resources);
            });
        }
    }

    public override MediaResource get_primary_resource () {
        var res = base.get_primary_resource ();

        // We don't have proper access to tbe bytes, but time seek should week
        res.dlna_operation = DLNAOperation.TIMESEEK;
        res.extension = "mpg";

        return res;
    }

    public override async void commit_custom (bool override_guarded)
                                              throws Error {
        if (this.node == null) {
            yield base.commit_custom (override_guarded);
        }
    }
}
