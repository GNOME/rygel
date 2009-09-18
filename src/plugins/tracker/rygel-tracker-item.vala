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
        MIME,
        SIZE,
        DATE,

        // Image
        IMAGE_TITLE,
        IMAGE_WIDTH,
        IMAGE_HEIGHT,
        IMAGE_ALBUM,
        IMAGE_DATE,
        CREATOR,

        // Audio
        AUDIO_TITLE,
        AUDIO_DURATION,
        AUDIO_ALBUM,
        ARTIST,
        TRACK_NUM,
        RELEASE,
        DATE_ADDED,

        // Video
        VIDEO_TITLE,
        VIDEO_WIDTH,
        VIDEO_HEIGHT,
        VIDEO_DURATION,
        AUTHOR,

        LAST_KEY
    }

    protected string path;

    public TrackerItem (string                 id,
                        string                 path,
                        TrackerSearchContainer parent,
                        string                 upnp_class,
                        string[]               metadata) {
        base (id, parent, "", upnp_class);

        this.path = path;

        if (metadata[Metadata.SIZE] != "")
            this.size = metadata[Metadata.SIZE].to_int ();

        if (metadata[Metadata.DATE] != "")
            this.date = seconds_to_iso8601 (metadata[Metadata.DATE]);

        this.mime_type = metadata[Metadata.MIME];

        this.add_uri (Filename.to_uri (path, null), null);
    }

    public static string[] get_metadata_keys () {
        string[] keys = new string[Metadata.LAST_KEY];
        keys[Metadata.FILE_NAME] = "File:Name";
        keys[Metadata.MIME] = "File:Mime";
        keys[Metadata.SIZE] = "File:Size";
        keys[Metadata.DATE] = "DC:Date";

        // Image metadata
        keys[Metadata.IMAGE_TITLE] = "Image:Title";
        keys[Metadata.CREATOR] = "Image:Creator";
        keys[Metadata.IMAGE_WIDTH] = "Image:Width";
        keys[Metadata.IMAGE_HEIGHT] = "Image:Height";
        keys[Metadata.IMAGE_ALBUM] = "Image:Album";
        keys[Metadata.IMAGE_DATE] = "Image:Date";

        // Audio metadata
        keys[Metadata.AUDIO_TITLE] = "Audio:Title";
        keys[Metadata.AUDIO_DURATION] = "Audio:Duration";
        keys[Metadata.ARTIST] = "Audio:Artist";
        keys[Metadata.AUDIO_ALBUM] = "Audio:Album";
        keys[Metadata.TRACK_NUM] = "Audio:TrackNo";
        keys[Metadata.RELEASE] = "Audio:ReleaseDate";
        keys[Metadata.DATE_ADDED] = "Audio:DateAdded";

        // Video metadata
        keys[Metadata.VIDEO_DURATION] = "Video:Duration";
        keys[Metadata.VIDEO_TITLE] = "Video:Title";
        keys[Metadata.AUTHOR] = "Video:Author";
        keys[Metadata.VIDEO_WIDTH] = "Video:Width";
        keys[Metadata.VIDEO_HEIGHT] = "Video:Height";

        return keys;
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

