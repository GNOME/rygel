/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008-2012 Nokia Corporation.
 * Copyright (C) 2010 MediaNet Inh.
 *
 * Authors: Zeeshan Ali <zeenix@gmail.com>
 *          Sunil Mohan Adapa <sunil@medhas.org>
 *          Jens Georg <jensg@openismus.com>
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
    private const string CATEGORY_IRI = "http://www.tracker-project.org/" +
                                        "temp/nmm#MusicPiece";

    public MusicItemFactory () {
        var upload_folder = Environment.get_user_special_dir
                                        (UserDirectory.MUSIC);
        try {
            var config = MetaConfig.get_default ();
            upload_folder = config.get_music_upload_folder ();
        } catch (Error error) {};

        base (CATEGORY, CATEGORY_IRI, MusicItem.UPNP_CLASS, upload_folder);

        // These must be the same order as enum MusicMetadata
        this.properties.add ("res@duration");
        this.properties.add ("upnp:album");
        this.properties.add ("upnp:artist");
        this.properties.add ("upnp:originalTrackNumber");
        this.properties.add ("upnp:genre");
        this.properties.add ("sampleRate");
        this.properties.add ("upnp:nrAudioChannels");
        this.properties.add ("upnp:bitsPerSample");
        this.properties.add ("upnp:bitrate");
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

        this.set_ref_id (item, "AllMusic");

        var music = item as MusicItem;

        if (metadata[MusicMetadata.DURATION] != "" &&
            metadata[MusicMetadata.DURATION] != "0") {
            music.duration = int.parse (metadata[MusicMetadata.DURATION]);
        }

        if (metadata[MusicMetadata.SAMPLE_RATE] != "") {
            music.sample_freq = int.parse
                                        (metadata[MusicMetadata.SAMPLE_RATE]);
        }

        if (metadata[MusicMetadata.CHANNELS] != "") {
            music.channels = int.parse (metadata[MusicMetadata.CHANNELS]);
        }

        if (metadata[MusicMetadata.BITS_PER_SAMPLE] != "") {
            var bits_per_sample = metadata[MusicMetadata.BITS_PER_SAMPLE];
            music.bits_per_sample = int.parse (bits_per_sample);
        }

        if (metadata[MusicMetadata.BITRATE] != "") {
            music.bitrate = int.parse (metadata[MusicMetadata.BITRATE]) / 8;
        }

        if (metadata[MusicMetadata.AUDIO_TRACK_NUM] != "") {
            var track_number = metadata[MusicMetadata.AUDIO_TRACK_NUM];
            music.track_number = int.parse (track_number);
        }

        // FIXME: For the following three properties:
        // Once converted to libtracker-sparql, check for null again.
        // DBus translates a (null) to ''
        if (metadata[MusicMetadata.AUDIO_ARTIST] != "") {
            music.artist = metadata[MusicMetadata.AUDIO_ARTIST];
        }

        if (metadata[MusicMetadata.AUDIO_ALBUM] != "") {
            music.album = metadata[MusicMetadata.AUDIO_ALBUM];
        }

        if (metadata[MusicMetadata.AUDIO_GENRE] != "") {
            music.genre = metadata[MusicMetadata.AUDIO_GENRE];
        }

        music.lookup_album_art ();
    }
}

