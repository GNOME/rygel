/*
 * Copyright (C) 2010 Jens Georg <mail@jensge.org>.
 * Copyright (C) 2012 Intel Corporation.
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

internal errordomain MediaArtStoreError {
    NO_DIR,
    NO_MEDIA_ART
}

/**
 * This maps RygelMusicItem objects to their cached cover art,
 * implementing the GNOME
 * [[https://live.gnome.org/MediaArtStorageSpec|MediaArt storage specification]].
 */
public class Rygel.MediaArtStore : GLib.Object {
    private static MediaArtStore media_art_store;
    private static bool first_time = true;

    private string directory;
    private MediaArt.Process? media_art_process;

    public static MediaArtStore? get_default () {
        if (first_time) {
            try {
                MediaArt.plugin_init (128);
                media_art_store = new MediaArtStore ();
            } catch (MediaArtStoreError error) {
                warning ("No media art available: %s", error.message);
            }
        }

        first_time = false;

        return media_art_store;
    }

    public Thumbnail? find_media_art (MusicItem item,
                                      bool      simple = false) throws Error {
        string[] types = { "track", "album", "artist", "podcast", "radio" };
        File file = null;

        foreach (var type in types) {
            file = this.get_media_art_file (type, item, simple);
            if (file != null && file.query_exists (null)) {
                break;
            } else {
                file = null;
            }
        }

        if (file == null) {
            return null;
        }

        var info = file.query_info (FileAttribute.ACCESS_CAN_READ + "," +
                                    FileAttribute.STANDARD_SIZE,
                                    FileQueryInfoFlags.NONE,
                                    null);
        if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)) {
            return null;
        }

        var thumb = new Thumbnail ();
        thumb.uri = file.get_uri ();
        thumb.size = (int64) info.get_size ();

        return thumb;
    }

    public Thumbnail? find_media_art_any (MusicItem item) throws Error {
        var thumb = this.find_media_art (item);

        return thumb;
    }

    public File? get_media_art_file (string    type,
                                     MusicItem item,
                                     bool      simple = false) {
        File file;

        MediaArt.get_file (item.artist,
                           type == "album" ? item.album : item.title,
                           type,
                           null,
                           out file,
                           null);

        return file;
    }

    public void add (MusicItem item, File file, uint8[]? data) {
        if (media_art_process == null) {
            return;
        }

        try {
            media_art_process.buffer (MediaArt.Type.ALBUM, MediaArt.ProcessFlags.NONE, file,
                                      data, item.mime_type, item.artist, item.album);
        } catch (Error error) {
            warning ("%s", error.message);
        }
    }

    private MediaArtStore () throws MediaArtStoreError {
        var dir = Path.build_filename (Environment.get_user_cache_dir (),
                                       "media-art");
        var file = File.new_for_path (dir);

        if (!file.query_exists (null)) {
            DirUtils.create_with_parents (dir, 0750);
        }

        this.directory = dir;

        try {
            this.media_art_process = new MediaArt.Process ();
        } catch (Error error) {
            this.media_art_process = null;
            throw new MediaArtStoreError.NO_MEDIA_ART ("%s", error.message);
        }
    }
}
