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

/**
 * A helper class to create container and item
 * instances based on media-export object IDs,
 * sometimes delegating to the QueryContainerFactory.
 */
internal class Rygel.MediaExport.ObjectFactory : Object {
    /**
     * Return a new instance of DBContainer.
     *
     * @param media_db instance of MediaDB
     * @param title title of the container
     * @param child_count number of children in the container
     */
    public virtual DBContainer get_container (string     id,
                                              string     title,
                                              uint       child_count,
                                              string?    uri) {
        if (id == "0") {
            return RootContainer.get_instance ();
        } else if (id == RootContainer.FILESYSTEM_FOLDER_ID) {
            var root_container = RootContainer.get_instance ();

            return root_container.get_filesystem_container ();
        }

        if (id.has_prefix (QueryContainer.PREFIX)) {
            var factory = QueryContainerFactory.get_default ();
            return factory.create_from_hashed_id (id, title);
        }

        if (id.has_prefix ("virtual-parent:" + Rygel.PlaylistItem.UPNP_CLASS)) {
            return new PlaylistRootContainer ();
        }

        // Return a suitable container for the top-level virtual folders.
        // This corresponds to the short-lived NullContainers that
        // we used to save these in the database.
        if (id.has_prefix ("virtual-parent:")) {
            return new DBContainer (id, title);
        }

        if (uri == null) {
            return new TrackableDbContainer (id, title);
        }

        if (id.has_prefix ("playlist:")) {
            return new PlaylistContainer (id, title);
        }

        // Return a writable container for anything with a URI,
        // such as child folders of the file system,
        // to allow uploads.
        // See https://bugzilla.gnome.org/show_bug.cgi?id=676379 to
        // give more control over this.
        return new WritableDbContainer (id, title);
    }

    /**
     * Return a new instance of MediaFileItem
     *
     * @param media_db instance of MediaDB
     * @param id id of the item
     * @param title title of the item
     * @param upnp_class upnp_class of the item
     */
    public virtual MediaFileItem get_item (MediaContainer parent,
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
            case Rygel.PlaylistItem.UPNP_CLASS:
                return new PlaylistItem (id, parent, title);
            default:
                assert_not_reached ();
        }
    }
}
