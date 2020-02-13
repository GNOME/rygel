/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
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
 * A simple implementation of RygelMediaContainer that keeps all RygelMediaObjects
 * in memory. You should add children via rygel_simple_container_add_child_item().
 */
public class Rygel.SimpleContainer : Rygel.MediaContainer,
                                     Rygel.SearchableContainer {
    public MediaObjects children;

    private MediaObjects empty_children;

    public ArrayList<string> search_classes { get; set; }

    /**
     * Creates a child RygelSimpleContainer.
     *
     * @param id The ID of the item. This should be unique in the server.
     * @param parent The parent of the container.
     * @param title The title of the container.
     */
    public SimpleContainer (string          id,
                            MediaContainer? parent,
                            string          title) {
        Object (id : id,
                parent : parent,
                title : title,
                child_count : 0);
    }

    public override void constructed () {
        base.constructed ();

        this.children = new MediaObjects ();
        this.empty_children = new MediaObjects ();
        this.search_classes = new ArrayList<string> ();
    }

    /**
     * Creates a RygelSimpleContainer as a root container.
     *
     * @param title The title of the container.
     */
    public SimpleContainer.root (string title) {
        Object (id : "0",
                parent : null,
                title : title,
                child_count : 0);
    }

    /**
     * Adds an item to the container.
     *
     * @param child The child item to add to the container.
     */
    public void add_child_item (MediaItem child) {
        this.add_child (child);
    }

    /**
     * Get all children, including the empty children.
     *
     * This is useful when all children are empty,
     * so get_children() would return no objects,
     * but when you need to add items to the empty
     * items.
     *
     * This is useful only when implementing derived classes.
     */
    protected MediaObjects get_all_children () {
        var all = new MediaObjects ();
        all.add_all (this.children);
        all.add_all (this.empty_children);

        return all;
    }

    /**
     * Adds a child container to this container.
     *
     * The child container will only be added to the hierarchy if, or when,
     * it contains some children.
     */
    public void add_child_container (MediaContainer child) {
        if (child is SearchableContainer) {
            var search_classes = ((SearchableContainer) child).search_classes;
            this.search_classes.add_all (search_classes);
        }

        if (child.child_count > 0) {
            this.add_child (child);
        } else {
            debug ("Container '%s' empty, refusing to add to hierarchy " +
                   "until it has any children to offer.",
                   child.id);
            this.empty_children.add (child);
            this.empty_child_count++;
            child.container_updated.connect (this.on_container_updated);
        }
    }

    /**
     * Removes the item from the container.
     */
    public void remove_child (MediaObject child) {
        this.children.remove (child);

        this.child_count--;
    }

    /**
     * Removes all child items and child containers
     * from the container.
     */
    public void clear () {
        // TODO: this will have to emit sub-tree events of object being deleted.
        this.children.clear ();

        this.child_count = 0;
    }

    /**
     * Check that the ID is unique within this container.
     *
     * This is useful only when implementing derived classes.
     *
     * @param child_id The ID to check for uniqueness.
     * @return true if the child ID is unique within this container.
     */
    protected bool is_child_id_unique (string child_id) {
        var unique = true;

        foreach (var child in this.children) {
            if (child.id == child_id) {
                unique = false;

                break;
            }
        }

        if (unique) {
            // Check the pending empty containers
            foreach (var child in this.empty_children) {
                if (child.id == child_id) {
                    unique = false;

                    break;
                }
            }
        }

        return unique;
    }

    public override async MediaObjects? get_children (
                                                     uint         offset,
                                                     uint         max_count,
                                                     string       sort_criteria,
                                                     Cancellable? cancellable)
                                                     throws Error {
        uint stop = offset + max_count;
        MediaObjects unsorted_children;

        if (this.create_mode_enabled) {
            stop = stop.clamp (0, this.all_child_count);
            unsorted_children = this.get_all_children ();
        } else {
            stop = stop.clamp (0, this.child_count);

            unsorted_children = this.children.slice (0, this.child_count)
                                        as MediaObjects;
        }

        unsorted_children.sort_by_criteria (sort_criteria);

        return unsorted_children.slice ((int) offset, (int) stop)
                                        as MediaObjects;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        MediaObject media_object = null;
        var max_count = 0;
        var restart_count = 0;
        var restart = false;

        if (this.create_mode_enabled) {
            max_count = this.all_child_count;
        } else {
            max_count = this.child_count;
        }
        var children_to_search = yield this.get_children (0,
                                                          max_count,
                                                          "",
                                                          cancellable);

        do {
            restart = false;
            ulong updated_id = 0;

            foreach (var child in children_to_search) {
                if (child.id == id) {
                    media_object = child;

                    break;
                } else if (child is MediaContainer) {
                    updated_id = this.container_updated.connect ( (_, updated) => {
                        if (updated == this) {
                            restart = true;
                            restart_count++;

                            // bail out on first update
                            this.disconnect (updated_id);
                            updated_id = 0;
                        }
                    });

                    var container = child as MediaContainer;
                    media_object = yield container.find_object (id, cancellable);

                    if (updated_id != 0) {
                        this.disconnect (updated_id);
                    }

                    if (media_object != null) {
                        // no need to loop when we've found what we were looking
                        // for
                        restart = false;

                        break;
                    }

                    if (restart) {
                        break;
                    }
                }
            }
        } while (restart && restart_count < 10);

        return media_object;
    }

    public async MediaObjects? search (SearchExpression? expression,
                                       uint              offset,
                                       uint              max_count,
                                       string            sort_criteria,
                                       Cancellable?      cancellable,
                                       out uint          total_matches)
                                       throws Error {
        return yield this.simple_search (expression,
                                         offset,
                                         max_count,
                                         sort_criteria,
                                         cancellable,
                                         out total_matches);
    }

    private void add_child (MediaObject child) {
        this.children.add (child);

        this.child_count++;
    }

    private void on_container_updated (MediaContainer source,
                                       MediaContainer updated,
                                       MediaObject object,
                                       ObjectEventType event_type,
                                       bool sub_tree_update) {
        if (updated.child_count > 0) {
            if (!(updated in this.empty_children)) {
                return;
            }

            this.empty_children.remove (updated);
            this.empty_child_count--;

            this.add_child (updated);

            this.updated ();

            debug ("Container '%s' now non-empty, added it to hierarchy now.",
                   updated.id);
        } else {
            if (!(updated in this.children)) {
                return;
            }

            this.remove_child (updated);
            this.empty_children.add (updated);
            this.empty_child_count++;

            this.updated ();

            debug ("Container '%s' now empty, removing it from hierarchy now.",
                   updated.id);
        }
    }
}
