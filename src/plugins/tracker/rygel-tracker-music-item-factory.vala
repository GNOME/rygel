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
using Tracker;

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

    public override MediaFileItem create (string          id,
                                          string          uri,
                                          SearchContainer parent,
                                          Sparql.Cursor   metadata)
                                          throws GLib.Error {
        var item = new MusicItem (id, parent, "");

        this.set_metadata (item, uri, metadata);

        return item;
    }

    protected override void set_metadata (MediaFileItem item,
                                          string        uri,
                                          Sparql.Cursor metadata)
                                          throws GLib.Error {
        base.set_metadata (item, uri, metadata);

        this.set_ref_id (item, "AllMusic");

        var music = item as MusicItem;

        if (metadata.is_bound (MusicMetadata.DURATION) &&
            metadata.get_string (MusicMetadata.DURATION) != "0") {
            music.duration = (long) metadata.get_integer
                                        (MusicMetadata.DURATION);
        }

        if (metadata.is_bound (MusicMetadata.SAMPLE_RATE)) {
            music.sample_freq = (int) metadata.get_integer
                                        (MusicMetadata.SAMPLE_RATE);
        }

        if (metadata.is_bound (MusicMetadata.CHANNELS)) {
            music.channels = (int) metadata.get_integer
                                        (MusicMetadata.CHANNELS);
        }

        if (metadata.is_bound (MusicMetadata.BITS_PER_SAMPLE)) {
            music.bits_per_sample = (int) metadata.get_integer
                                        (MusicMetadata.BITS_PER_SAMPLE);
        }

        if (metadata.is_bound (MusicMetadata.BITRATE)) {
            music.bitrate = (int) metadata.get_integer
                                        (MusicMetadata.BITRATE) / 8;
        }

        if (metadata.is_bound (MusicMetadata.AUDIO_TRACK_NUM)) {
            music.track_number = (int) metadata.get_integer
                                        (MusicMetadata.AUDIO_TRACK_NUM);
        }

        if (metadata.is_bound (MusicMetadata.AUDIO_ARTIST)) {
            music.artist = metadata.get_string (MusicMetadata.AUDIO_ARTIST);
        }

        if (metadata.is_bound (MusicMetadata.AUDIO_ALBUM)) {
            music.album = metadata.get_string (MusicMetadata.AUDIO_ALBUM);
        }

        if (metadata.is_bound (MusicMetadata.AUDIO_GENRE)) {
            music.genre = metadata.get_string (MusicMetadata.AUDIO_GENRE);
        }

        music.lookup_album_art ();
    }
}

