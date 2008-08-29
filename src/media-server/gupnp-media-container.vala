/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

public class GUPnP.MediaContainer : MediaObject {
    public uint child_count;

    public MediaContainer (string id,
                           string parent_id,
                           string title,
                           uint   child_count) {
        this.id = id;
        this.parent_id = parent_id;
        this.title = title;
        this.child_count = child_count;
    }

    public override void serialize (DIDLLiteWriter didl_writer) {
        didl_writer.start_container (this.id,
                                     this.parent_id,
                                     (int) this.child_count,
                                     false,
                                     false);

        didl_writer.add_string ("class",
                                DIDLLiteWriter.NAMESPACE_UPNP,
                                null,
                                "object.container.storageFolder");

        didl_writer.add_string ("title",
                                DIDLLiteWriter.NAMESPACE_DC,
                                null,
                                this.title);

        /* End of Container */
        didl_writer.end_container ();
    }
}
