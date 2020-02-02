/*
 * Copyright (C) 2013 Intel Corporation.
 *
 * Author: Jussi Kukkonen <jussi.kukkonen@intel.com>
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

using Rygel;
using Sqlite;

public class Rygel.LMS.ImageYear : Rygel.LMS.CategoryContainer {
    private const string SQL_ALL_TEMPLATE =
        "SELECT images.id, title, artist, date, width, height, path, size, " +
        "dlna_profile, dlna_mime, strftime('%Y', date, 'unixepoch') as year " +
        "FROM images, files " +
        "WHERE dtime = 0 AND images.id = files.id AND year = '%s' " +
        "LIMIT ? OFFSET ?;";

    private const string SQL_COUNT_TEMPLATE =
        "SELECT count(images.id), strftime('%Y', date, 'unixepoch') as year " +
        "FROM images, files " +
        "WHERE dtime = 0 AND images.id = files.id AND year = '%s';";

    private const string SQL_FIND_OBJECT_TEMPLATE =
        "SELECT images.id, title, artist, date, width, height, path, size, " +
        "dlna_profile, dlna_mime, strftime('%Y', date, 'unixepoch') as year " +
        "FROM images, files " +
        "WHERE dtime = 0 AND files.id = ? AND images.id = files.id AND year = '%s';";

    private const string SQL_ADDED_TEMPLATE =
        "SELECT images.id, title, artist, date, width, height, path, size, " +
        "dlna_profile, dlna_mime, strftime('%Y', date, 'unixepoch') as year " +
        "FROM images, files " +
        "WHERE dtime = 0 AND images.id = files.id AND year = '%s' " +
        "AND update_id > ? AND update_id <= ?;";

    private const string SQL_REMOVED_TEMPLATE =
        "SELECT images.id, title, artist, date, width, height, path, size, " +
        "dlna_profile, dlna_mime, strftime('%Y', date, 'unixepoch') as year " +
        "FROM images, files " +
        "WHERE dtime <> 0 AND images.id = files.id AND year = '%s' " +
        "AND update_id > ? AND update_id <= ?;";

    protected override MediaObject? object_from_statement
                                        (Statement statement) {
        var id = statement.column_int (0);
        var path = statement.column_text (6);
        var mime_type = statement.column_text (9);

        if (mime_type == null || mime_type.length == 0){
            /* TODO is this correct? */
            debug ("Image item %d (%s) has no MIME type", id, path);
        }

        var title = statement.column_text (1);
        var image = new ImageItem (this.build_child_id (id), this, title);
        image.ref_id = this.build_reference_id (id);
        image.creator = statement.column_text (2);
        var dt = new DateTime.from_unix_utc ((long) statement.column_int (3));
        image.date = "%sZ".printf (dt.format ("%Y-%m-%dT%H:%M:%S"));
        image.width = statement.column_int (4);
        image.height = statement.column_int (5);
        image.size = statement.column_int (7);
        image.mime_type = mime_type;
        image.dlna_profile = statement.column_text (8);
        var file = File.new_for_path (path);
        image.add_uri (file.get_uri ());

        return image;
    }

    private static string get_sql_all (string year) {
        return (SQL_ALL_TEMPLATE.printf (year));
    }
    private static string get_sql_find_object (string year) {
        return (SQL_FIND_OBJECT_TEMPLATE.printf (year));
    }
    private static string get_sql_count (string year) {
        return (SQL_COUNT_TEMPLATE.printf (year));
    }
    private static string get_sql_added (string year) {
        return (SQL_ADDED_TEMPLATE.printf (year));
    }
    private static string get_sql_removed (string year) {
        return (SQL_REMOVED_TEMPLATE.printf (year));
    }

    public ImageYear (MediaContainer parent,
                      string         year,
                      LMS.Database   lms_db) {
        base ("%s".printf (year),
              parent,
              year,
              lms_db,
              get_sql_all (year),
              get_sql_find_object (year),
              get_sql_count (year),
              get_sql_added (year),
              get_sql_removed (year));
    }
}
