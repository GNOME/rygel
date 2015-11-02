/*
 * Copyright (C) 2010-2014 Jens Georg <mail@jensge.org>.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <mail@jensge.org>
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
    private const string[] types = { "track", "album", "artist", "podcast", "radio", "video" };

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

    public Thumbnail? lookup_media_art (MusicItem item) throws Error {
        File file = null;

        foreach (var type in MediaArtStore.types) {
            if (type == "album" && item.album == null && item.artist == null) {
                continue;
            } else if (item.artist == null && item.title == null) {
                continue;
            }

            MediaArt.get_file (item.artist,
                               type == "album" ? item.album : item.title,
                               type,
                               out file);

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

    public void add (MusicItem item, File file, uint8[] data, string mime) {
        if (this.media_art_process == null) {
            return;
        }

        try {
            this.media_art_process.buffer (MediaArt.Type.ALBUM,
                                           MediaArt.ProcessFlags.NONE,
                                           file,
                                           data,
                                           mime,
                                           item.artist,
                                           item.album);
        } catch (Error error) {
            warning (_("Failed to add album art for %s: %s"),
                     file.get_uri (),
                     error.message);
        }
    }

    public void search_media_art_for_file (MusicItem item, File file) {
        try {
            this.media_art_process.file (MediaArt.Type.ALBUM,
                                         MediaArt.ProcessFlags.NONE,
                                         file,
                                         item.artist,
                                         item.album);
        } catch (Error error) {
            warning (_("Failed to find media art for %s: %s"),
                     file.get_uri (),
                     error.message);
        }
    }

    private MediaArtStore () throws MediaArtStoreError {
        try {
            this.media_art_process = new MediaArt.Process ();
        } catch (Error error) {
            this.media_art_process = null;
            throw new MediaArtStoreError.NO_MEDIA_ART ("%s", error.message);
        }
    }
}
