/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
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

using Gee;

/**
 * A simple implementation of MediaContainer that keeps all MediaObjects
 * in memory. In order for it to be of any use, you must add children to
 * children ArrayList field.
 */
public class Rygel.SimpleContainer : Rygel.MediaContainer {
    public ArrayList<MediaObject> children;

    public SimpleContainer (string          id,
                            MediaContainer? parent,
                            string          title) {
        base (id, parent, title, 0);

        this.children = new ArrayList<MediaObject> ();
    }

    public SimpleContainer.root (string title) {
        this ("0", null, title);
    }

    public void add_child (MediaObject child) {
        this.children.add (child);

        this.child_count++;
    }

    public void remove_child (MediaObject child) {
        this.children.remove (child);

        this.child_count--;
    }

    public override async Gee.List<MediaObject>? get_children (
                                        uint         offset,
                                        uint         max_count,
                                        Cancellable? cancellable)
                                        throws Error {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);

        return this.children.slice ((int) offset, (int) stop);
    }
}
