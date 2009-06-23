/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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
 * Represents a media object (container and item).
 */
public abstract class Rygel.MediaObject : GLib.Object {
    public string id;
    public string title;

    // You can keep both a unowned and owned ref to parent of this MediaObject.
    // In most cases, one will only need to keep an unowned ref to avoid cyclic
    // references since usually parent container will keep refs to child items.
    // However in some cases, one only wants the parent to exist as long as the
    // child exists and it is in those cases, you will want to use 'parent_ref'.
    //
    // You must set 'parent' if you set 'parent_ref' but the opposite is not
    // mandatory.
    public unowned MediaContainer parent;
    public MediaContainer parent_ref;
}
