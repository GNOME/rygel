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

internal class Rygel.MediaExportObjectFactory : MediaDBObjectFactory {
    public override MediaContainer get_container (MediaDB media_db,
                                                  string  id,
                                                  string  title,
                                                  uint    child_count) {
        if (id.has_prefix (MediaExportQueryContainer.PREFIX)) {
            return new MediaExportQueryContainer (media_db, id, title);
        } else {
            return new MediaExportWritableContainer (media_db, id, title);
        }
    }
}
