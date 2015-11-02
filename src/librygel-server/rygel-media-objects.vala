/*
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Gee;
using GUPnP;

/**
 * An array list that keeps media objects.
 */
public class Rygel.MediaObjects : ArrayList<MediaObject> {
    public const string SORT_CAPS = "@id,@parentID,dc:title,upnp:class," +
                                    "upnp:artist,upnp:author,upnp:album," +
                                    "dc:date,upnp:originalTrackNumber";

    public override Gee.List<MediaObject>? slice (int start, int stop) {
        var slice = base.slice (start, stop);
        var ret = new MediaObjects ();

        ret.add_all (slice);

        return ret;
    }

    public void sort_by_criteria (string sort_criteria) {
        var sort_props = sort_criteria.split (",");
        if (sort_props.length == 0) {
            return;
        }

        this.sort ((a, b) => {
            var object_a = a as MediaObject;
            var object_b = b as MediaObject;

            return this.compare_media_objects (object_a, object_b, sort_props);
        });
    }

    internal void serialize (Serializer   serializer,
                             HTTPServer   http_server,
                             ClientHacks? hacks) throws Error {
        foreach (var result in this) {
            if (hacks != null) {
                hacks.apply (result);
            }

            result.serialize (serializer, http_server);
        }
    }

    private int compare_media_objects (MediaObject a,
                                       MediaObject b,
                                       string[]    sort_props) {
        int i;
        int ret = 0;

        for (i = 0; ret == 0 && i < sort_props.length; i++) {
            var property = sort_props [i].substring (1);

            ret = a.compare_by_property (b, property);

            if (sort_props [i][0] == '-') {
                // Need it in descending order so reverse the comparison
                ret = 0 - ret;
            }
        }

        return ret;
    }
}
