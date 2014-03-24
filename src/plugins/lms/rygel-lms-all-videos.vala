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

public class Rygel.LMS.AllVideos : Rygel.LMS.CategoryContainer {
    private static const string SQL_ALL =
        "SELECT videos.id, title, artist, length, path, mtime, size, dlna_profile, dlna_mime " +
        "FROM videos, files " +
        "WHERE dtime = 0 AND videos.id = files.id " +
        "LIMIT ? OFFSET ?;";

   private static const string SQL_COUNT =
        "SELECT count(videos.id) " +
        "FROM videos, files " +
        "WHERE dtime = 0 AND videos.id = files.id;";

    private static const string SQL_FIND_OBJECT =
        "SELECT videos.id, title, artist, length, path, mtime, size, dlna_profile, dlna_mime " +
        "FROM videos, files " +
        "WHERE dtime = 0 AND files.id = ? AND videos.id = files.id;";

    protected override MediaObject? object_from_statement (Statement statement) {
        var id = statement.column_int(0);
        var mime_type = statement.column_text(8);
        var path = statement.column_text(4);
        var file = File.new_for_path(path);

        /* TODO: Temporary code to extract the MIME TYPE.  LMS does not seem
           to compute the mime type of videos.  Don't know why. */

/*        if (mime_type == null || mime_type.length == 0) {
            try {
                FileInfo info = file.query_info(FileAttribute.STANDARD_CONTENT_TYPE,
                                                FileQueryInfoFlags.NONE, null);
                mime_type = info.get_content_type();
            } catch {}
        }
*/

        if (mime_type == null || mime_type.length == 0) {
            /* TODO is this correct? */
            debug ("Video item %d (%s) has no MIME type",
                   id,
                   path);
            }

        var title = statement.column_text(1);
        var video = new VideoItem(this.build_child_id (id), this, title);
        video.creator = statement.column_text(2);
        video.duration = statement.column_int(3);
        TimeVal tv = { (long) statement.column_int(5), (long) 0 };
        video.date = tv.to_iso8601 ();
        video.size = statement.column_int(6);
        video.dlna_profile = statement.column_text(7);
        video.mime_type = mime_type;
        video.add_uri (file.get_uri ());

        // Rygel does not support multiple video and audio tracks in a single file,
        // so we just take the first one
        var video_data = "select videos_videos.bitrate + videos_audios.bitrate, width, height, channels, sampling_rate " +
            "from videos, videos_audios, videos_videos where videos.id = ? " +
            "and videos.id = videos_audios.video_id and videos.id = videos_videos.video_id;";
        try {
            var stmt = this.lms_db.prepare(video_data);
            Rygel.LMS.Database.find_object("%d".printf(id), stmt);
            video.bitrate = stmt.column_int(0) / 8; //convert bits per second into bytes per second
            video.width = stmt.column_int(1);
            video.height = stmt.column_int(2);
            video.channels = stmt.column_int(3);
            video.sample_freq = stmt.column_int(4);
        } catch (DatabaseError e) {
            warning ("Query failed: %s", e.message);
        }

        return video;
    }

    public AllVideos (string id, MediaContainer parent, string title, LMS.Database lms_db){
        base (id,
              parent,
              title,
              lms_db,
              AllVideos.SQL_ALL,
              AllVideos.SQL_FIND_OBJECT,
              AllVideos.SQL_COUNT);
    }
}
