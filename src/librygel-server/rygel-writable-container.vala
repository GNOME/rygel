/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010-2012 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
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

public errordomain Rygel.WritableContainerError {
    NOT_IMPLEMENTED = 602
}

/**
 * This interface should be implemented by 'writable' containers - ones that allow
 * adding (via upload), removal and editing of items directly under them.
 * Currently, only addition and removal are supported.
 *
 * In addition to implementing this interface, a writable container must also:
 *
 *  # Provide one URI that points to a writable folder on a GIO-supported filesystem.
 *  # Monitor not only its own URI but also that of its child items, though the latter is implied in the former if you use GIO for monitoring.
 */
public interface Rygel.WritableContainer : MediaContainer {
    public static const string WRITABLE_SCHEME = "rygel-writable://";

    //TODO: The valadoc gtk-doc doclet doesn't use the property's documentation
    //on getters and setters:
    //https://bugzilla.gnome.org/show_bug.cgi?id=684193

    /**
     * The list of upnp classes that can be added to this container.
     *
     * See rygel_writable_container_add_item().
     *
     * This corresponds to the UPnP ContentDirectory's createClass properties.
     */
    public abstract ArrayList<string> create_classes { get; set; }

    /**
     * Check if this container can contain an item with the given upnp class,
     * meaning that rygel_writable_container_add_item() should succeed.
     *
     * @param upnp_class The upnp class of an item to check
     *
     * @return true if it can, false, if not.
     */
    public bool can_create (string upnp_class) {
        return this.create_classes.contains (upnp_class);
    }

    //TODO: See this bug if we want to support adding of child containers too:
    //https://bugzilla.gnome.org/show_bug.cgi?id=684196

    /**
     * Add a new item directly under this container.
     *
     * The caller should not first create the file(s) pointed to by the item's URI(s). That
     * is handled by the container class.
     *
     * This method corresponds to the UPnP ContentDirectory's CreateObject action.
     *
     * @param item The item to add to this container
     * @param cancellable optional cancellable for this operation
     *
     * @return nothing.
     */
    public async abstract void add_item (MediaFileItem item,
                                         Cancellable?  cancellable) throws Error;


    /**
     * Add a new container directly under this container.
     *
     * @param container The container to add to this container
     * @param cancellable optional cancellable for this operation
     **/
    public async abstract void add_container (MediaContainer container,
                                              Cancellable?   cancellable)
                                              throws Error;

    /**
     * Add a reference to an object.
     * @param object The source object to add a reference to.
     * @param cancellable optional cancellable for this operation
     * @return the id of the newly created reference
     **/
    public async virtual string add_reference (MediaObject    object,
                                               Cancellable? cancellable)
                                               throws Error {
        throw new WritableContainerError.NOT_IMPLEMENTED
                                        ("Cannot create references here");
    }

    /**
     * Remove an item directly under this container that has the ID @id.
     *
     * The caller should not first remove the file(s) pointed to by the item's URI(s). That
     * is handled by the container class.
     *
     * This method corresponds to the UPnP ContentDirectory's DestroyObject action.
     *
     * @param id The ID of the item to remove from this container
     * @param cancellable optional cancellable for this operation
     *
     * @return nothing.
     */
    public async abstract void remove_item (string id, Cancellable? cancellable)
                                            throws Error;

    /**
     * Remove a container directly under this container that has the ID @id.
     *
     * The caller should not first remove the file(s) pointed to by the item's URI(s). That
     * is handled by the container class.
     *
     * This method corresponds to the UPnP ContentDirectory's DestroyObject action.
     *
     * @param id The ID of the item to remove from this container
     * @param cancellable optional cancellable for this operation
     */
    public async abstract void remove_container (string       id,
                                                 Cancellable? cancellable)
                                                 throws Error;
}
