/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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
using GUPnP;
using Gee;
using Rygel.Database;

public class Rygel.MediaExport.DBContainer : MediaContainer,
                                             SearchableContainer {
    protected MediaCache media_db;
    public ArrayList<string> search_classes { get; set; }

    public DBContainer (string id, string title) {
        Object (id : id,
                parent : null,
                title : title,
                child_count : 0);
    }

    public override void constructed () {
        base.constructed ();

        this.media_db = MediaCache.get_default ();
        this.search_classes = new ArrayList<string> ();
        // Items
        this.search_classes.add (Rygel.ImageItem.UPNP_CLASS);
        this.search_classes.add (Rygel.PhotoItem.UPNP_CLASS);
        this.search_classes.add (Rygel.VideoItem.UPNP_CLASS);
        this.search_classes.add (Rygel.AudioItem.UPNP_CLASS);
        this.search_classes.add (Rygel.MusicItem.UPNP_CLASS);
        this.search_classes.add (Rygel.PlaylistItem.UPNP_CLASS);

        // Containers
        this.search_classes.add (Rygel.MediaContainer.UPNP_CLASS);
        this.container_updated.connect ( () => {
                this.child_count = this.count_children ();
            });
        this.child_count = this.count_children ();
    }

    public virtual int count_children () {
        try {
            return this.media_db.get_child_count (this.id);
        } catch (DatabaseError error) {
            debug ("Could not get child count from database: %s",
                   error.message);
            return 0;
        }
    }

    public override async MediaObjects? get_children (
                                                     uint         offset,
                                                     uint         max_count,
                                                     string       sort_criteria,
                                                     Cancellable? cancellable)
                                                     throws GLib.Error {
        return this.media_db.get_children (this,
                                           sort_criteria,
                                           offset,
                                           max_count);
    }

    public virtual async MediaObjects? search (SearchExpression? expression,
                                               uint              offset,
                                               uint              max_count,
                                               string            sort_criteria,
                                               Cancellable?      cancellable,
                                               out uint          total_matches)
                                               throws GLib.Error {
        MediaObjects children = null;

        try {
            children = this.media_db.get_objects_by_search_expression
                                        (expression,
                                         this.id,
                                         sort_criteria,
                                         offset,
                                         max_count,
                                         out total_matches);
        } catch (MediaCacheError error) {
            if (error is MediaCacheError.UNSUPPORTED_SEARCH) {
                children = yield this.simple_search (expression,
                                                     offset,
                                                     max_count,
                                                     sort_criteria,
                                                     cancellable,
                                                     out total_matches);
            } else {
                throw error;
            }
        }

        return children;
    }

    public override async MediaObject? find_object (string       id,
                                                    Cancellable? cancellable)
                                                    throws Error {
        return this.media_db.get_object (id);
    }
}
