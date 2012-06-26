/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010-2012 Nokia Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
 *         Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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
 * Interface to be implemented by 'writable' container: ones that allow
 * creation, removal and editing of items directly under them. Currently, only
 * addition and removal is supported.
 *
 * In addition to implementing this interface, a writable container must also:
 *
 * 1. Provide one URI that points to a writable folder on a GIO supported
 *    filesystem.
 * 2. Monitor not only it's own URI but also that of it's child items, though
 *    the latter is implied in the former if you use GIO for monitoring.
 */
public interface Rygel.WritableContainer : MediaContainer {
    // List of classes that an object in this container could be created of
    public abstract ArrayList<string> create_classes { get; set; }

    /**
     * Check if this container claims to be able to create an item with the
     * given upnp class.
     *
     * @param upnp_class The class of an item to check
     *
     * @return true if it can, false, if not.¨
     */
    public bool can_create (string upnp_class) {
        return this.create_classes.contains (upnp_class);
    }

    /**
     * Add a new item directly under this container.
     *
     * This doesn't imply creation of file(s) pointed to by item's URI(s), that
     * is handled for you.
     *
     * @param item The item to add to this container
     * @param cancellable optional cancellable for this operation
     *
     * @return nothing.
     *
     */
    public async abstract void add_item (MediaItem    item,
                                         Cancellable? cancellable) throws Error;

    /**
     * Remove an item directly under this container that has the ID @id.
     *
     * This doesn't imply deletion of file(s) pointed to by item's URI(s), that
     * is handled for you.
     *
     * @param item The ID of the item to remove from this container
     * @param cancellable optional cancellable for this operation
     *
     * @return nothing.
     *
     */
    public async abstract void remove_item (string id, Cancellable? cancellable)
                                            throws Error;
}
