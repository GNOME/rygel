/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using Rygel;
using GUPnP;
using Gst;

/**
 * Represents Test item.
 */
public abstract class Rygel.TestItem : Rygel.MediaItem {
    const string TEST_AUTHOR = "Zeeshan Ali (Khattak)";

    public TestItem (string   id,
                     string   parent_id,
                     string   title,
                     string   mime,
                     string   upnp_class,
                     Streamer streamer) {
        base (id, parent_id, title, upnp_class, streamer);

        this.res.mime_type = mime;
        this.author = TEST_AUTHOR;
    }

    public abstract Element create_gst_source () throws Error;
}

