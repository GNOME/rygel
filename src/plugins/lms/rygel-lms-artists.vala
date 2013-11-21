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

public class Rygel.LMS.Artists : Rygel.LMS.CategoryContainer {
    private static const string SQL_ALL =
        "SELECT audio_artists.id, audio_artists.name " +
        "FROM audio_artists " +
        "LIMIT ? OFFSET ?;";

    private static const string SQL_COUNT =
        "SELECT COUNT(audio_artists.id) " +
        "FROM audio_artists;";

    private static const string SQL_FIND_OBJECT =
        "SELECT audio_artists.id, audio_artists.name " +
        "FROM audio_artists " +
        "WHERE audio_artists.id = ?;";

    protected override MediaObject? object_from_statement (Statement statement) {
        var db_id = "%d".printf (statement.column_int (0));
        var title = statement.column_text (1);

        return new LMS.Artist (db_id, this, title, this.lms_db);
    }

    public Artists (string id,
                    MediaContainer parent,
                    string title,
                    LMS.Database   lms_db) {
        base (id,
              parent,
              title,
              lms_db,
              Artists.SQL_ALL,
              Artists.SQL_FIND_OBJECT,
              Artists.SQL_COUNT);
    }
}
