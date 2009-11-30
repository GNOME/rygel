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
 * Represents Tracker item.
 */
public abstract class Rygel.TrackerItem : Rygel.MediaItem {
    protected enum Metadata {
        FILE_NAME,
        TITLE,
        MIME,
        SIZE,
        DATE,

        // Image and Video
        HEIGHT,
        WIDTH,

        // Audio and Video
        DURATION,

        // Audio
        AUDIO_ALBUM,
        AUDIO_ARTIST,
        AUDIO_TRACK_NUM,

        LAST_KEY
    }

    protected string path;

    public TrackerItem (string                 id,
                        string                 path,
                        TrackerSearchContainer parent,
                        string                 upnp_class,
                        string[]               metadata)
                        throws GLib.Error {
        base (id, parent, "", upnp_class);

        this.path = path;

        if (metadata[Metadata.TITLE] != "")
            this.title = metadata[Metadata.TITLE];
        else
            /* If title wasn't provided, use filename instead */
            this.title = metadata[Metadata.FILE_NAME];

        if (metadata[Metadata.SIZE] != "")
            this.size = metadata[Metadata.SIZE].to_int ();

        if (metadata[Metadata.DATE] != "")
            this.date = seconds_to_iso8601 (metadata[Metadata.DATE]);

        this.mime_type = metadata[Metadata.MIME];

        this.add_uri (Filename.to_uri (path, null), null);
    }

    public static string[] get_metadata_keys () {
        string[] keys = new string[Metadata.LAST_KEY];
        keys[Metadata.FILE_NAME] = "nfo:fileName";
        keys[Metadata.TITLE] = "nie:title";
        keys[Metadata.MIME] = "nie:mimeType";
        keys[Metadata.SIZE] = "nfo:fileSize";
        keys[Metadata.DATE] = "dc:date";

        // Image and Video metadata
        keys[Metadata.WIDTH] = "nfo:width";
        keys[Metadata.HEIGHT] = "nfo:height";

        // Audio and Video metadata
        keys[Metadata.DURATION] = "nmm:length";

        // Audio metadata
        keys[Metadata.AUDIO_ARTIST] = "nmm:performer";
        keys[Metadata.AUDIO_ALBUM] = "nmm:musicAlbum";
        keys[Metadata.AUDIO_TRACK_NUM] = "nmm:trackNumber";

        return keys;
    }

    public int get_num_metadata_keys () {
        return Metadata.LAST_KEY;
    }

    protected string seconds_to_iso8601 (string seconds) {
        string date;

        if (seconds != "") {
            TimeVal tv = TimeVal ();

            tv.tv_sec = seconds.to_int ();
            tv.tv_usec = 0;

            date = tv.to_iso8601 ();
        } else {
            date = "";
        }

        return date;
    }
}

