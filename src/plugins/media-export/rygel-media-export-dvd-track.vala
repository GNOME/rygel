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

internal class Rygel.MediaExport.DVDTrack : Rygel.VideoItem {
    public Xml.Node* node { private get; construct set; }
    public int track { private get; construct set; }

    public DVDTrack (string         id,
                     MediaContainer parent,
                     int            track,
                     Xml.Node*      node) {
        Object (id : id,
                parent : parent,
                node : node,
                title : _("Title %d").printf (track + 1),
                upnp_class : Rygel.VideoItem.UPNP_CLASS,
                track : track);
    }

    public override void constructed () {
        base.constructed ();

        var uri = new Soup.URI (this.parent.get_uris ()[0]);
        uri.set_scheme ("dvd");
        uri.set_query ("title=%d".printf (track + 1));
        this.add_uri (uri.to_string (false));

        this.dlna_profile = "MPEG_PS";
        this.mime_type = "video/mpeg";

        var it = node->children;
        while (it != null) {
            if (it->name == "length") {
                this.duration = (int)double.parse (it->children->content);
            } else if (it->name == "width") {
                this.width = int.parse (it->children->content);
            } else if (it->name == "height") {
                this.height = int.parse (it->children->content);
            } else if (it->name == "PAL") {
                this.dlna_profile = "MPEG_PS_PAL";
            } else if (it->name == "NTSC") {
                this.dlna_profile = "MPEG_PS_NTSC";
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

    public override MediaResource get_primary_resource () {
        var res = base.get_primary_resource ();

        // We don't have proper access to tbe bytes, but time seek should week
        res.dlna_operation = DLNAOperation.TIMESEEK;
        res.extension = "mpg";

        return res;
    }
}
