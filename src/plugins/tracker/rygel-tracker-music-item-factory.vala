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
        AUDIO_GENRE,
        SAMPLE_RATE,
        CHANNELS,
        BITS_PER_SAMPLE,
        BITRATE,

        LAST_KEY
    }

    private const string CATEGORY = "nmm:MusicPiece";

    public MusicItemFactory () {
        base (CATEGORY,
              MusicItem.UPNP_CLASS,
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
        this.key_chains[MusicMetadata.AUDIO_GENRE].add ("nfo:genre");
        this.key_chains[MusicMetadata.SAMPLE_RATE].add ("nfo:sampleRate");
        this.key_chains[MusicMetadata.CHANNELS].add ("nfo:channels");
        this.key_chains[MusicMetadata.BITS_PER_SAMPLE].add (
                                        "nfo:bitsPerSample");
        this.key_chains[MusicMetadata.BITRATE].add ("nfo:averageBitrate");
    }

    public override MediaItem create (string          id,
                                      string          uri,
                                      SearchContainer parent,
                                      string[]        metadata)
                                      throws GLib.Error {
        var item = new MusicItem (id, parent, "");

        this.set_metadata (item, uri, metadata);

        return item;
    }

    protected override void set_metadata (MediaItem item,
                                          string    uri,
                                          string[]  metadata)
                                          throws GLib.Error {
        base.set_metadata (item, uri, metadata);

        var music = item as MusicItem;

        if (metadata[MusicMetadata.DURATION] != "" &&
            metadata[MusicMetadata.DURATION] != "0") {
            music.duration = metadata[MusicMetadata.DURATION].to_int ();
        }

        if (metadata[MusicMetadata.SAMPLE_RATE] != "") {
            music.sample_freq = metadata[MusicMetadata.SAMPLE_RATE].to_int ();
        }

        if (metadata[MusicMetadata.CHANNELS] != "") {
            music.channels = metadata[MusicMetadata.CHANNELS].to_int ();
        }

        if (metadata[MusicMetadata.BITS_PER_SAMPLE] != "") {
            var bits_per_sample = metadata[MusicMetadata.BITS_PER_SAMPLE];
            music.bits_per_sample = bits_per_sample.to_int ();
        }

        if (metadata[MusicMetadata.BITRATE] != "") {
            music.bitrate = metadata[MusicMetadata.BITRATE].to_int () / 8;
        }

        if (metadata[MusicMetadata.AUDIO_TRACK_NUM] != "") {
            var track_number = metadata[MusicMetadata.AUDIO_TRACK_NUM];
            music.track_number = track_number.to_int ();
        }

        music.artist = metadata[MusicMetadata.AUDIO_ARTIST];
        music.album = metadata[MusicMetadata.AUDIO_ALBUM];
        music.genre = metadata[MusicMetadata.AUDIO_GENRE];

        music.lookup_album_art ();
    }
}

