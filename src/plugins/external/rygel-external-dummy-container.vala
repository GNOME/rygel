/*
 * Copyright (C) 2009,2010 Jens Georg <mail@jensge.org>.
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Jens Georg <mail@jensge.org>
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

using Rygel;
using Gee;

/**
 * This is a dummy container used to satisfy rygel when creating objects for
 * search resuts.
 */
internal class Rygel.External.DummyContainer : MediaContainer {
    public DummyContainer (string          id,
                           string          title,
                           uint            child_count,
                           MediaContainer? parent) {
        base (id, parent, title, (int) child_count);
    }

    public override async MediaObjects? get_children (
                                                     uint         offset,
                                                     uint         max_count,
                                                     string       sort_criteria,
                                                     Cancellable? cancellable)
                                                     throws Error {
        return new MediaObjects ();
    }

     public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        return null;
    }
}
