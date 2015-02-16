/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * The simple media engine does not use GStreamer or any other
 * multimedia framework. Therefore its capabilities are limited.
 *
 * It does not support transcoding - get_resources() returns null.
 * Also, its RygelSimpleDataSource does not support time-base seeking.
 */
internal class Rygel.SimpleMediaEngine : MediaEngine {
    private List<DLNAProfile> profiles = new List<DLNAProfile> ();

    public SimpleMediaEngine () { }

    public override unowned List<DLNAProfile> get_dlna_profiles() {
        return this.profiles;
    }

    public override async Gee.List<MediaResource> ? get_resources_for_item
                                                        (MediaObject object) {
        if (! (object is MediaFileItem)) {
            warning ("Can only process file-based MediaObjects (MediaFileItems)");
            return null;
        }

        var item = object as MediaFileItem;

        // For MediaFileItems, uri 0 is the file URI referring directly to the content
        string source_uri = item.get_primary_uri ();
        if (!source_uri.has_prefix ("file://")) {
            warning ("Can't process non-file uri " + source_uri);
        }

        debug ("get_resources_for_item (%s)", source_uri);

        Gee.List<MediaResource> resources = new Gee.ArrayList<MediaResource> ();

        var primary_res = item.get_primary_resource ();

        // The SimpleMediaEngine supports only byte-based seek
        primary_res.dlna_operation = GUPnP.DLNAOperation.RANGE;

        // The SimpleMediaEngine supports connection stalling on
        primary_res.dlna_flags |= DLNAFlags.CONNECTION_STALL;

        // Add a resource for http consumption (as SimpleMediaEngine can handle http)
        MediaResource http_res = new MediaResource.from_resource ("primary_http",
                                                                  primary_res);
        http_res.uri = ""; // The URI needs to be assigned by the MediaServer
        resources.add (http_res);

        resources.add (primary_res);

        return resources;
    }

    public override DataSource? create_data_source_for_resource (MediaObject object,
                                                                 MediaResource resource)
        throws Error {
        if (! (object is MediaFileItem)) {
            warning ("Can only process file-based MediaObjects (MediaFileItems)");
            return null;
        }

        // For MediaFileItems, the primary URI referrs to the local content file
        string source_uri = object.get_primary_uri ();
        return new SimpleDataSource (source_uri);
    }

    public override DataSource? create_data_source_for_uri (string uri) {
        if (!uri.has_prefix ("file://")) {
            return null;
        }
        debug ("creating data source for %s", uri);
        return new SimpleDataSource (uri);
    }
}

public static Rygel.MediaEngine module_get_instance () {
    return new Rygel.SimpleMediaEngine ();
}
