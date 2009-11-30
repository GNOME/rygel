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

using GUPnP;
using DBus;

/**
 * Tracker music item factory.
 */
public class Rygel.TrackerMusicItemFactory : Rygel.TrackerItemFactory {
    public const string CATEGORY = "nmm:MusicPiece";

    public override MediaItem create (string                 id,
                                      string                 path,
                                      TrackerSearchContainer parent,
                                      string?                upnp_class,
                                      string[]               metadata)
                                      throws GLib.Error {
        var item = base.create (id,
                                path,
                                parent,
                                MediaItem.MUSIC_CLASS,
                                metadata);

        if (metadata[Metadata.DURATION] != "")
            item.duration = metadata[Metadata.DURATION].to_int ();

        if (metadata[Metadata.AUDIO_TRACK_NUM] != "")
            item.track_number = metadata[Metadata.AUDIO_TRACK_NUM].to_int ();

        if (metadata[Metadata.DATE] != "") {
            item.date = seconds_to_iso8601 (metadata[Metadata.DATE]);
        }

        item.author = metadata[Metadata.AUDIO_ARTIST];
        item.album = metadata[Metadata.AUDIO_ALBUM];

        return item;
    }
}

