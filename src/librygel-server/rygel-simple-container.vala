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
public class Rygel.SimpleContainer : Rygel.MediaContainer,
                                     Rygel.SearchableContainer {
    public MediaObjects children;

    private MediaObjects empty_children;

    public ArrayList<string> search_classes { get; set; }

    public SimpleContainer (string          id,
                            MediaContainer? parent,
                            string          title) {
        base (id, parent, title, 0);

        this.children = new MediaObjects ();
        this.empty_children = new MediaObjects ();
        this.search_classes = new ArrayList<string> ();
    }

    public SimpleContainer.root (string title) {
        this ("0", null, title);
    }

    public void add_child_item (MediaItem child) {
        this.add_child (child);
    }

    public MediaObjects get_all_children () {
        var all = new MediaObjects ();
        all.add_all (this.children);
        all.add_all (this.empty_children);

        return all;
    }

    /**
     * NOTE: This method only actually adds the child container to the hierarchy
     * until it has any children to offer.
     */
    public void add_child_container (MediaContainer child) {
        if (child is SearchableContainer) {
            var search_classes = (child as SearchableContainer).search_classes;
            this.search_classes.add_all (search_classes);
        }

        if (child.child_count > 0) {
            this.add_child (child);
        } else {
            debug ("Container '%s' empty, refusing to add to hierarchy " +
                   "until it has any children to offer.",
                   child.id);
            this.empty_children.add (child);
            child.container_updated.connect (this.on_container_updated);
        }
    }

    public void remove_child (MediaObject child) {
        this.children.remove (child);

        this.child_count--;
    }

    public void clear () {
        this.children.clear ();

        this.child_count = 0;
    }

    public bool is_child_id_unique (string child_id) {
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
                                                     string?      sort_criteria,
                                                     Cancellable? cancellable)
                                                     throws Error {
        uint stop = offset + max_count;
        stop = stop.clamp (0, this.child_count);

        var sorted_children = this.children.slice (0, this.child_count)
                                        as MediaObjects;
        sorted_children.sort_by_criteria (sort_criteria ?? this.sort_criteria);

        return sorted_children.slice ((int) offset, (int) stop)
                                        as MediaObjects;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        MediaObject media_object = null;
        var restart_count = 0;
        var restart = false;

        do {
            restart = false;
            ulong updated_id = 0;

            foreach (var child in this.children) {
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
                                       out uint          total_matches,
                                       string?           sort_criteria,
                                       Cancellable?      cancellable)
                                       throws Error {
        return yield this.simple_search (expression,
                                         offset,
                                         max_count,
                                         out total_matches,
                                         sort_criteria ?? this.sort_criteria,
                                         cancellable);
    }

    private void add_child (MediaObject child) {
        this.children.add (child);

        this.child_count++;
    }

    private void on_container_updated (MediaContainer source,
                                       MediaContainer updated) {
        if (updated.child_count > 0) {
            if (!(updated in this.empty_children)) {
                return;
            }

            this.empty_children.remove (updated);

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

            this.updated ();

            debug ("Container '%s' now empty, removing it from hierarchy now.",
                   updated.id);
        }
    }
}
