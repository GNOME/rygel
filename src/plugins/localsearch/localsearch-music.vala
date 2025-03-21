/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

/**
 * Container listing Music content hierarchy.
 */
public class Rygel.LocalSearch.Music : CategoryContainer {
    public Music (string id, MediaContainer parent, string title) {
        base (id, parent, title, new MusicItemFactory ());

        this.add_child_container (new Artists (this));
        this.add_child_container (new Albums (this));
        this.add_child_container (new Genre (this));
        this.search_classes.add (AudioItem.UPNP_CLASS);
        this.search_classes.add (MusicItem.UPNP_CLASS);
        this.add_create_class (AudioItem.UPNP_CLASS);
    }
}
