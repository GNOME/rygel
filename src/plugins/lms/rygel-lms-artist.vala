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

public class Rygel.LMS.Artist : Rygel.LMS.CategoryContainer {
    private static const string SQL_ALL_TEMPLATE =
        "SELECT audio_albums.id, audio_albums.name " +
        "FROM audio_albums " +
        "WHERE audio_albums.artist_id = %s " +
        "LIMIT ? OFFSET ?;";

    private static const string SQL_COUNT_TEMPLATE =
        "SELECT COUNT(audio_albums.id) " +
        "FROM audio_albums " +
        "WHERE audio_albums.artist_id = %s";

    private static const string SQL_FIND_OBJECT_TEMPLATE =
        "SELECT audio_albums.id, audio_albums.name " +
        "FROM audio_albums " +
        "WHERE audio_albums.id = ? AND audio_albums.artist_id = %s;";

    private static string get_sql_all (string id) {
        return (SQL_ALL_TEMPLATE.printf (id));
    }
    private static string get_sql_find_object (string id) {
        return (SQL_FIND_OBJECT_TEMPLATE.printf (id));
    }
    private static string get_sql_count (string id) {
        return (SQL_COUNT_TEMPLATE.printf (id));
    }

    protected override MediaObject? object_from_statement (Statement statement) {
        var db_id = "%d".printf (statement.column_int (0));
        var title = statement.column_text (1);
        return new LMS.Album (db_id, this, title, this.lms_db);
    }

    public Artist (string         id,
                   MediaContainer parent,
                   string         title,
                   LMS.Database   lms_db) {

        base (id,
              parent,
              title,
              lms_db,
              get_sql_all (id),
              get_sql_find_object (id),
              get_sql_count (id));
    }
}
