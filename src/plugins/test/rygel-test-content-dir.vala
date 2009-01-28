/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel;
using GUPnP;
using Gee;

/**
 * Implementation of ContentDirectory service, meant for testing purposes only.
 */
public class Rygel.TestContentDir : ContentDirectory {
    /* Pubic methods */
    public override Gee.List<MediaObject> get_root_children (
                                                 uint     offset,
                                                 uint     max_count,
                                                 out uint child_count)
                                                 throws GLib.Error {
        var children = this.root_container.get_children (offset,
                                                         max_count,
                                                         out child_count);
        if (children == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return children;
    }

    public override MediaObject find_object_by_id (string object_id)
                                                   throws GLib.Error {
        var media_object = this.root_container.find_object_by_id (object_id);
        if (media_object == null) {
            throw new ContentDirectoryError.NO_SUCH_OBJECT ("No such object");
        }

        return media_object;
    }

    public override MediaContainer? create_root_container () {
        string friendly_name = this.root_device.get_friendly_name ();
        return new TestRootContainer (friendly_name, this.http_server);
    }
}

