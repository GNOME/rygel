/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

internal class Rygel.MediaExport.ObjectFactory : Object {
    /**
     * Return a new instance of DBContainer
     *
     * @param media_db instance of MediaDB
     * @param title title of the container
     * @param child_count number of children in the container
     */
    public virtual DBContainer get_container (MediaCache media_db,
                                              string     id,
                                              string     title,
                                              uint       child_count,
                                              string?    uri) {
        if (id == "0") {
            try {
                return RootContainer.get_instance () as DBContainer;
            } catch (Error error) {
                // Must not fail - plugin is disabled if this fails
                assert_not_reached ();
            }
        } else if (id == RootContainer.FILESYSTEM_FOLDER_ID) {
            try {
                var root_container = RootContainer.get_instance ()
                                        as RootContainer;

                return root_container.get_filesystem_container ()
                                        as DBContainer;
            } catch (Error error) { assert_not_reached (); }
        }

        if (id.has_prefix (QueryContainer.PREFIX)) {
            var factory = QueryContainerFactory.get_default ();
            return factory.create_from_id (media_db, id, title);
        }

        if (uri == null) {
            return new DBContainer (media_db, id, title);
        }

        return new WritableDbContainer (media_db, id, title);
    }

    /**
     * Return a new instance of MediaItem
     *
     * @param media_db instance of MediaDB
     * @param id id of the item
     * @param title title of the item
     * @param upnp_class upnp_class of the item
     */
    public virtual MediaItem get_item (MediaCache     media_db,
                                       MediaContainer parent,
                                       string         id,
                                       string         title,
                                       string         upnp_class) {
        switch (upnp_class) {
            case Rygel.MusicItem.UPNP_CLASS:
            case Rygel.AudioItem.UPNP_CLASS:
                return new MusicItem (id, parent, title);
            case Rygel.VideoItem.UPNP_CLASS:
                return new VideoItem (id, parent, title);
            case Rygel.PhotoItem.UPNP_CLASS:
            case Rygel.ImageItem.UPNP_CLASS:
                return new PhotoItem (id, parent, title);
            default:
                assert_not_reached ();
        }
    }
}
