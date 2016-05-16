/*
 * Copyright (C) 2015 Jens Georg <mail@jensge.org>.
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

using Gst;
using Gst.PbUtils;
using Rygel.MediaExport;

internal errordomain InfoSerializerError {
    INVALID_STREAM,
    BAD_MIME
}

internal class Rygel.InfoSerializer : GLib.Object {
    private VariantType? t = null;

    public Variant serialize (VariantDict in_v) throws Error {
        return new Variant ("(smvmvmvmvmvmv)",
                            in_v.lookup_value
                            (Serializer.UPNP_CLASS, this.t).get_string (),
                            this.serialize_file_info (in_v),
                            this.serialize_dlna_profile (in_v),
                            this.serialize_info (in_v),
                            this.serialize_audio_info (in_v),
                            this.serialize_video_info (in_v),
                            this.serialize_meta_data (in_v));
    }

    private Variant serialize_file_info (VariantDict in_v) {
        return new Variant ("(stst)",
                            in_v.lookup_value (Serializer.TITLE,
                                this.t).get_string (),
                            in_v.lookup_value (Serializer.MODIFIED,
                                this.t).get_uint64 (),
                            in_v.lookup_value (Serializer.MIME_TYPE,
                                this.t).get_string (),
                            in_v.lookup_value (Serializer.SIZE,
                                this.t).get_uint64 ());
    }

    private Variant? serialize_dlna_profile (VariantDict in_v) {
        var val = in_v.lookup_value (Serializer.DLNA_PROFILE, this.t);
        if (val == null) {
            return null;
        }

        return new Variant ("(ss)",
                            val.get_string (),
                            in_v.lookup_value
                            (Serializer.MIME_TYPE, this.t).get_string ());
    }

    private Variant? serialize_info (VariantDict in_v) {
        long duration = -1;
        in_v.lookup (Serializer.DURATION, "i", out duration);

        string? title = null;
        in_v.lookup (Serializer.TITLE, "s", out title);

        string? date = null;
        in_v.lookup (Serializer.DATE, "s", out date);

        return new Variant ("(msmsi)",
                            title,
                            date,
                            duration);
    }

    private Variant? serialize_video_info (VariantDict in_v) {
        int width = -1;
        int height = -1;
        int depth = -1;

        in_v.lookup (Serializer.VIDEO_WIDTH, "i", out width);
        in_v.lookup (Serializer.VIDEO_HEIGHT, "i", out height);
        in_v.lookup (Serializer.VIDEO_DEPTH, "i", out depth);


        if (width == -1 && height == -1) {
            return null;
        }

        return new Variant ("(iii)", width, height, depth);
    }

    private Variant? serialize_audio_info (VariantDict in_v) {
        int channels = -1;
        int rate = -1;

        in_v.lookup (Serializer.AUDIO_CHANNELS, "i", out channels);
        in_v.lookup (Serializer.AUDIO_RATE, "i", out rate);

        if (channels == -1 && rate == -1) {
            return null;
        }

        return new Variant ("(ii)", channels, rate);
    }

    private Variant? serialize_meta_data (VariantDict in_v) {
        string artist = null;
        in_v.lookup (Serializer.ARTIST, "s", out artist);

        string album = null;
        in_v.lookup (Serializer.ALBUM, "s", out album);

        string genre = null;
        in_v.lookup (Serializer.GENRE, "s", out genre);

        int volume = -1;
        in_v.lookup (Serializer.VOLUME_NUMBER, "i", out volume);

        int track = -1;
        in_v.lookup (Serializer.TRACK_NUMBER, "i", out track);

        int bitrate = -1;
        in_v.lookup (Serializer.AUDIO_BITRATE, "i", out bitrate);

        if (artist == null && album == null && genre == null &&
            volume == -1 && track == -1 && bitrate == -1) {
            return null;
        }

        return new Variant ("(msmsmsiii)",
                            artist,
                            album,
                            genre,
                            volume,
                            track,
                            bitrate);
    }
}
