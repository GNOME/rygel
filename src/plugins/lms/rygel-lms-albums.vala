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
using Rygel.Database;
using Sqlite;

public class Rygel.LMS.Albums : Rygel.LMS.CategoryContainer {
    private const string SQL_ALL =
        "SELECT audio_albums.id, audio_albums.name as title, " +
               "audio_artists.name as artist " +
        "FROM audio_albums " +
        "LEFT JOIN audio_artists " +
        "ON audio_albums.artist_id = audio_artists.id " +
        "LIMIT ? OFFSET ?;";

    private const string SQL_ALL_WITH_FILTER_TEMPLATE =
        "SELECT audio_albums.id, audio_albums.name as title, " +
               "audio_artists.name as artist " +
        "FROM audio_albums " +
        "LEFT JOIN audio_artists " +
        "ON audio_albums.artist_id = audio_artists.id " +
        "WHERE %s " +
        "LIMIT ? OFFSET ?;";

    private const string SQL_COUNT =
        "SELECT COUNT(audio_albums.id) " +
        "FROM audio_albums;";

    private const string SQL_COUNT_WITH_FILTER_TEMPLATE =
        "SELECT COUNT(audio_albums.id), audio_albums.name as title, " +
               "audio_artists.name as artist " +
        "FROM audio_albums " +
        "LEFT JOIN audio_artists " +
        "ON audio_albums.artist_id = audio_artists.id " +
        "WHERE %s;";

    /* count songs inside albums */
    private const string SQL_CHILD_COUNT_WITH_FILTER_TEMPLATE =
        "SELECT COUNT(audios.id), audios.title as title, " +
               "audio_artists.name as artist " +
        "FROM audios, files, audio_albums " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "WHERE dtime = 0 AND audios.id = files.id AND audios.album_id = audio_albums.id %s;";

    /* select songs inside albums */
    private const string SQL_CHILD_ALL_WITH_FILTER_TEMPLATE =
        "SELECT files.id, files.path, files.size, " +
               "audios.title as title, audios.trackno, audios.length, audios.channels, audios.sampling_rate, audios.bitrate, audios.dlna_profile, audios.dlna_mime, " +
               "audio_artists.name as artist, " +
               "audio_albums.name, audio_albums.id " +
        "FROM audios, files, audio_albums " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "WHERE dtime = 0 AND audios.id = files.id AND audios.album_id = audio_albums.id %s " +
        "LIMIT ? OFFSET ?;";


    private const string SQL_FIND_OBJECT =
        "SELECT audio_albums.id, audio_albums.name " +
        "FROM audio_albums " +
        "WHERE audio_albums.id = ?;";

    protected override string get_sql_all_with_filter (string filter) {
        if (filter.length == 0) {
            return Albums.SQL_ALL;
        }
        return (Albums.SQL_ALL_WITH_FILTER_TEMPLATE.printf (filter));
    }

    protected override string get_sql_count_with_filter (string filter) {
        if (filter.length == 0) {
            return Albums.SQL_COUNT;
        }
        return (Albums.SQL_COUNT_WITH_FILTER_TEMPLATE.printf (filter));
    }

    protected override uint get_child_count_with_filter (string     where_filter,
                                                         ValueArray args) {

        /* search the children (albums) as usual */
        var count = base.get_child_count_with_filter (where_filter, args);

        /* now search the album contents */
        var filter = "";
        if (where_filter.length > 0) {
            filter = "AND %s".printf (where_filter);
        }
        var query = Albums.SQL_CHILD_COUNT_WITH_FILTER_TEMPLATE.printf (filter);
        try {
            count += this.lms_db.query_value (query, args.values);
        } catch (DatabaseError e) {
            warning ("Query failed: %s", e.message);
        }

        return count;
    }

    protected override MediaObjects? get_children_with_filter
                                            (string     where_filter,
                                             ValueArray args,
                                             string     sort_criteria,
                                             uint       offset,
                                             uint       max_count) {
        var children = base. get_children_with_filter (where_filter,
                                                       args,
                                                       sort_criteria,
                                                       offset,
                                                       max_count);
        var filter = "";
        if (where_filter.length > 0) {
            filter = "AND %s".printf (where_filter);
        }
        var query = Albums.SQL_CHILD_ALL_WITH_FILTER_TEMPLATE.printf (filter);
        try {
            var cursor = this.lms_db.exec_cursor (query, args.values);
            foreach (var stmt in cursor) {
                var album_id = stmt.column_text (13);
                var album = new Album (album_id, this, "", this.lms_db);

                var song = album.object_from_statement (stmt);
                song.parent_ref = song.parent;
                children.add (song);

            }
        } catch (DatabaseError e) {
            warning ("Query failed: %s", e.message);
        }

        return children;
    }

    protected override MediaObject? object_from_statement (Statement statement) {
        var id = "%d".printf (statement.column_int (0));
        LMS.Album album = new LMS.Album (id,
                                         this,
                                         statement.column_text (1),
                                         this.lms_db);
        return album;
    }

    public Albums (MediaContainer parent,
                   LMS.Database   lms_db) {
        base ("albums",
              parent,
              _("Albums"),
              lms_db,
              Albums.SQL_ALL,
              Albums.SQL_FIND_OBJECT,
              Albums.SQL_COUNT,
              null, null);
    }
}
