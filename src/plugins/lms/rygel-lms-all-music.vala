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

public class Rygel.LMS.AllMusic : Rygel.LMS.CategoryContainer {
    private const string SQL_ALL_TEMPLATE =
        "SELECT files.id, files.path, files.size, " +
               "audios.title as title, audios.trackno, audios.length, " +
               "audios.channels, audios.sampling_rate, audios.bitrate, " +
               "audios.dlna_profile, audios.dlna_mime, " +
               "audio_artists.name as artist, " +
               "audio_albums.name, " +
               "files.mtime, " +
               "audio_genres.name " +
        "FROM audios, files " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "LEFT JOIN audio_albums " +
        "ON audios.album_id = audio_albums.id " +
        "LEFT JOIN audio_genres " +
        "ON audios.genre_id = audio_genres.id " +
        "WHERE dtime = 0 AND audios.id = files.id %s " +
        "LIMIT ? OFFSET ?;";

    private const string SQL_COUNT =
        "SELECT COUNT(audios.id) " +
        "FROM audios, files " +
        "WHERE dtime = 0 AND audios.id = files.id;";

    private const string SQL_COUNT_WITH_FILTER_TEMPLATE =
        "SELECT COUNT(audios.id), audios.title as title, " +
               "audio_artists.name as artist " +
        "FROM audios, files " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "WHERE dtime = 0 AND audios.id = files.id %s;";

    private const string SQL_FIND_OBJECT =
        "SELECT files.id, files.path, files.size, " +
               "audios.title, audios.trackno, audios.length, " +
               "audios.channels, audios.sampling_rate, audios.bitrate, " +
               "audios.dlna_profile, audios.dlna_mime, " +
               "audio_artists.name, " +
               "audio_albums.name, " +
               "files.mtime, " +
               "audio_genres.name " +
        "FROM audios, files " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "LEFT JOIN audio_albums " +
        "ON audios.album_id = audio_albums.id " +
        "LEFT JOIN audio_genres " +
        "ON audios.genre_id = audio_genres.id " +
        "WHERE dtime = 0 AND files.id = ? AND audios.id = files.id;";

    private const string SQL_ADDED =
        "SELECT files.id, files.path, files.size, " +
               "audios.title as title, audios.trackno, audios.length, " +
               "audios.channels, audios.sampling_rate, audios.bitrate, " +
               "audios.dlna_profile, audios.dlna_mime, " +
               "audio_artists.name as artist, " +
               "audio_albums.name, " +
               "files.mtime, " +
               "audio_genres.name " +
        "FROM audios, files " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "LEFT JOIN audio_albums " +
        "ON audios.album_id = audio_albums.id " +
        "LEFT JOIN audio_genres " +
        "ON audios.genre_id = audio_genres.id " +
        "WHERE dtime = 0 AND audios.id = files.id " +
        "AND update_id > ? AND update_id <= ?;";

    private const string SQL_REMOVED =
        "SELECT files.id, files.path, files.size, " +
               "audios.title as title, audios.trackno, audios.length, " +
               "audios.channels, audios.sampling_rate, audios.bitrate, " +
               "audios.dlna_profile, audios.dlna_mime, " +
               "audio_artists.name as artist, " +
               "audio_albums.name, " +
               "files.mtime, " +
               "audio_genres.name " +
        "FROM audios, files " +
        "LEFT JOIN audio_artists " +
        "ON audios.artist_id = audio_artists.id " +
        "LEFT JOIN audio_albums " +
        "ON audios.album_id = audio_albums.id " +
        "LEFT JOIN audio_genres " +
        "ON audios.genre_id = audio_genres.id " +
        "WHERE dtime <> 0 AND audios.id = files.id " +
        "AND update_id > ? AND update_id <= ?;";

    protected override string get_sql_all_with_filter (string filter) {
        if (filter.length == 0) {
            return this.sql_all;
        }

        var filter_str = "AND %s".printf (filter);

        return (AllMusic.SQL_ALL_TEMPLATE.printf (filter_str));
    }

    protected override string get_sql_count_with_filter (string filter) {
        if (filter.length == 0) {
            return this.sql_count;
        }

        var filter_str = "AND %s".printf (filter);

        return (AllMusic.SQL_COUNT_WITH_FILTER_TEMPLATE.printf (filter_str));
    }

    protected override MediaObject? object_from_statement
                                        (Statement statement) {
        var id = statement.column_int (0);
        var path = statement.column_text (1);
        var mime_type = statement.column_text (10);

        if (mime_type == null || mime_type.length == 0) {
            /* TODO is this correct? */
            debug ("Music item %d (%s) has no MIME type", id, path);
        }

        var title = statement.column_text (3);
        var song_id = this.build_child_id (id);
        var song = new MusicItem (song_id, this, title);
        song.size = statement.column_int (2);
        song.track_number = statement.column_int (4);
        song.duration = statement.column_int (5);
        song.channels = statement.column_int (6);
        song.sample_freq = statement.column_int (7);
        song.bitrate = statement.column_int (8);
        song.dlna_profile = statement.column_text (9);
        song.mime_type = mime_type;
        song.artist = statement.column_text (11);
        song.album = statement.column_text (12);
        var dt = new DateTime.from_unix_utc ((long) statement.column_int (13));
        song.date = "%sZ".printf (dt.format ("%Y-%m-%dT%H:%M:%S"));
        song.genre = statement.column_text (14);
        var file = File.new_for_path (path);
        song.add_uri (file.get_uri ());

        return song;
    }

    public AllMusic (MediaContainer parent, LMS.Database lms_db) {
        base("all",
             parent,
             _("All"),
             lms_db,
             AllMusic.SQL_ALL_TEMPLATE.printf (""),
             AllMusic.SQL_FIND_OBJECT,
             AllMusic.SQL_COUNT,
             AllMusic.SQL_ADDED,
             AllMusic.SQL_REMOVED);
    }
}
