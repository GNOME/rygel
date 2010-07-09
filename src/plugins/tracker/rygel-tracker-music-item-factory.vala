/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Gee;

/**
 * Tracker music item factory.
 */
public class Rygel.Tracker.MusicItemFactory : ItemFactory {
    private enum MusicMetadata {
        DURATION = Metadata.LAST_KEY,
        AUDIO_ALBUM,
        AUDIO_ARTIST,
        AUDIO_TRACK_NUM,

        LAST_KEY
    }

    private const string CATEGORY = "nmm:MusicPiece";

    public MusicItemFactory () {
        base (CATEGORY,
              MediaItem.MUSIC_CLASS,
              MUSIC_RESOURCES_CLASS_PATH,
              Environment.get_user_special_dir (UserDirectory.MUSIC));

        for (var i = this.key_chains.size; i < MusicMetadata.LAST_KEY; i++) {
            this.key_chains.add (new ArrayList<string> ());
        }

        this.key_chains[MusicMetadata.DURATION].add ("nfo:duration");
        this.key_chains[MusicMetadata.AUDIO_ARTIST].add ("nmm:performer");
        this.key_chains[MusicMetadata.AUDIO_ARTIST].add ("nmm:artistName");
        this.key_chains[MusicMetadata.AUDIO_ALBUM].add ("nmm:musicAlbum");
        this.key_chains[MusicMetadata.AUDIO_ALBUM].add ("nmm:albumTitle");
        this.key_chains[MusicMetadata.AUDIO_TRACK_NUM].add ("nmm:trackNumber");
    }

    public override MediaItem create (string          id,
                                      string          uri,
                                      SearchContainer parent,
                                      string[]               metadata)
                                      throws GLib.Error {
        var item = base.create (id, uri, parent, metadata);

        if (metadata[MusicMetadata.DURATION] != "")
            item.duration = metadata[MusicMetadata.DURATION].to_int ();

        if (metadata[MusicMetadata.AUDIO_TRACK_NUM] != "") {
            var track_number = metadata[MusicMetadata.AUDIO_TRACK_NUM];
            item.track_number = track_number.to_int ();
        }

        item.author = metadata[MusicMetadata.AUDIO_ARTIST];
        item.album = metadata[MusicMetadata.AUDIO_ALBUM];

        return item;
    }
}

