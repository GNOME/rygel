/*
 * Copyright (C) 2016 Jens Georg <mail@jensge.org>
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

namespace Rygel.MediaExport.Serializer {
    // Generic things - always set
    public const string UPNP_CLASS = "UPnPClass";
    public const string ID = "Id";
    public const string URI = "Uri";
    public const string TITLE = "Title";
    public const string DATE = "Date";

    // Item things - always set
    public const string MODIFIED = "MTime";
    public const string MIME_TYPE = "MimeType";
    public const string SIZE = "Size";

    // Item things
    public const string DLNA_PROFILE = "DLNAProfile";

    // AudioItem
    public const string DURATION = "Duration";
    public const string AUDIO_CHANNELS = "AudioChannels";
    public const string AUDIO_RATE = "AudioRate";
    public const string AUDIO_BITRATE = "AudioBitrate";

    // VisualItem
    public const string VIDEO_WIDTH = "VideoWidth";
    public const string VIDEO_HEIGHT = "VideoHeight";
    public const string VIDEO_DEPTH = "VideoDepth";

    // MusicItem
    public const string ARTIST = "Artist";
    public const string ALBUM = "Album";
    public const string GENRE = "Genre";
    public const string VOLUME_NUMBER = "VolumeNumber";
    public const string TRACK_NUMBER = "TrackNumber";
}
