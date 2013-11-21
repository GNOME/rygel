/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

using Rygel;
using Sqlite;

public class Rygel.LMS.AllImages : Rygel.LMS.CategoryContainer {
    private static const string SQL_ALL =
        "SELECT images.id, title, artist, date, width, height, path, size, dlna_profile, dlna_mime " +
        "FROM images, files " +
        "WHERE images.id = files.id " +
        "LIMIT ? OFFSET ?;";

    private static const string SQL_COUNT =
        "SELECT count(images.id) " +
        "FROM images, files " +
        "WHERE images.id = files.id;";

    private static const string SQL_FIND_OBJECT =
        "SELECT images.id, title, artist, date, width, height, path, size, dlna_profile, dlna_mime " +
        "FROM images, files " +
        "WHERE files.id = ? AND images.id = files.id;";

    protected override MediaObject? object_from_statement (Statement statement) {
        var id = statement.column_int(0);
        var path = statement.column_text(6);
        var mime_type = statement.column_text(9);

        if (mime_type == null || mime_type.length == 0){
            /* TODO is this correct? */
            debug ("Skipping music item %d (%s) with no MIME type",
                   id,
                   path);
            return null;
        }

        var title = statement.column_text(1);
        var image = new ImageItem(this.build_child_id (id), this, title);
        image.creator = statement.column_text(2);
        TimeVal tv = { (long) statement.column_int(3), (long) 0 };
        image.date = tv.to_iso8601 ();
        image.width = statement.column_int(4);
        image.height = statement.column_int(5);
        image.size = statement.column_int(7);
        image.mime_type = mime_type;
        image.dlna_profile = statement.column_text(8);
        File file = File.new_for_path(path);
        image.add_uri (file.get_uri ());

        return image;
    }

    public AllImages (MediaContainer parent, LMS.Database lms_db) {
        base ("all",
              parent,
              _("All"),
              lms_db,
              AllImages.SQL_ALL,
              AllImages.SQL_FIND_OBJECT,
              AllImages.SQL_COUNT);
    }
}
