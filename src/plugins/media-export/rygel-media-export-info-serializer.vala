/*
 * Copyright (C) 2015 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
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

using Gst;
using Gst.PbUtils;

internal errordomain InfoSerializerError {
    INVALID_STREAM,
    BAD_MIME
}

internal class Rygel.InfoSerializer : GLib.Object {
    public MediaArt.Process? media_art { get; construct set; }

    public InfoSerializer (MediaArt.Process? media_art) {
        GLib.Object (media_art: media_art);
    }

    public Variant serialize (File               file,
                              FileInfo           file_info,
                              DiscovererInfo?    info,
                              GUPnPDLNA.Profile? dlna_profile) throws Error {
        // Guess UPnP class
        if (info != null) {
            string? upnp_class = null;

            var audio_streams = (GLib.List<DiscovererAudioInfo>)
                                            info.get_audio_streams ();
            var video_streams = (GLib.List<DiscovererVideoInfo>)
                                            info.get_video_streams ();
            if (audio_streams == null && video_streams == null) {
                debug ("%s had neither audio nor video/picture " +
                       "streams. Ignoring.",
                       file.get_uri ());

                throw new InfoSerializerError.INVALID_STREAM ("No stream information");
            }

            if (audio_streams == null && video_streams.data.is_image ()) {
                upnp_class = UPNP_CLASS_PHOTO;
            } else if (video_streams != null) {
                upnp_class = UPNP_CLASS_VIDEO;
            } else if (audio_streams != null) {
                upnp_class = UPNP_CLASS_MUSIC;
            } else {
                // Uh...
            }

            return new Variant ("(smvmvmvmvmvmv)",
                                upnp_class,
                                this.serialize_file_info (file_info),
                                this.serialize_dlna_profile (dlna_profile),
                                this.serialize_info (info),
                                this.serialize_audio_info (audio_streams != null ?
                                                           audio_streams.data : null),
                                this.serialize_video_info (video_streams != null ?
                                                           video_streams.data : null),
                                this.serialize_meta_data (file, audio_streams != null ?
                                                          audio_streams.data : null));
        } else {
            string? upnp_class = null;
            var mime = ContentType.get_mime_type (file_info.get_content_type ());
            if (mime.has_prefix ("video/")) {
                upnp_class = UPNP_CLASS_VIDEO;
            } else if (mime.has_prefix ("image/")) {
                upnp_class = UPNP_CLASS_PHOTO;
            } else if (mime.has_prefix ("audio/") || mime == "application/ogg") {
                upnp_class = UPNP_CLASS_MUSIC;
            } else if (mime.has_suffix ("/xml")) { // application/xml or text/xml
                upnp_class = UPNP_CLASS_PLAYLIST;
            } else {
                debug ("Unsupported content-type %s, skipping %s…",
                       mime,
                       file.get_uri ());

                throw new InfoSerializerError.BAD_MIME ("Not supported: %s", mime);
            }

            return new Variant ("(ssmvmvmvmvmvmv)",
                                file.get_uri (),
                                upnp_class,
                                this.serialize_file_info (file_info),
                                null,
                                null,
                                null,
                                null,
                                null);
        }
    }

    private Variant serialize_file_info (FileInfo info) {
        return new Variant ("(sstt)",
                            info.get_display_name (),
                            ContentType.get_mime_type
                                        (info.get_content_type ()),
                            info.get_attribute_uint64
                                        (FileAttribute.TIME_MODIFIED),
                            info.get_size ());
    }

    private Variant? serialize_dlna_profile (GUPnPDLNA.Profile? profile) {
        if (profile == null) {
            return null;
        }

        return new Variant ("(ss)", profile.name, profile.mime);
    }

    private Variant? serialize_info (DiscovererInfo? info) {
        long duration = -1;
        if (info.get_duration () > 0) {
            duration = (long) (info.get_duration () / Gst.SECOND);
        }

        var tags = info.get_tags ();
        string? title = null;
        if (tags != null) {
            tags.get_string (Tags.TITLE, out title);
        }

        string date = null;
        Gst.DateTime? dt = null;
        if (tags != null && tags.get_date_time (Tags.DATE_TIME, out dt)) {
            // Make a minimal valid iso8601 date - bgo#702231
            // This mostly happens with MP3 files which only have a year
            if (!dt.has_day () || !dt.has_month ()) {
                date = "%d-%02d-%02d".printf (dt.get_year (),
                                              dt.has_month () ?
                                                  dt.get_month () : 1,
                                              dt.has_day () ?
                                                  dt.get_day () : 1);
            } else {
                date = dt.to_iso8601_string ();
            }
        }

        return new Variant ("(msmsi)",
                            title,
                            date,
                            duration);
    }

    private Variant? serialize_video_info (DiscovererVideoInfo? info) {
        if (info == null) {
            return null;
        }

        return new Variant ("(iii)",
                            (int) info.get_width (),
                            (int) info.get_height (),
                            info.get_depth () > 0 ?
                                info.get_depth () : -1);
    }

    private Variant? serialize_audio_info (DiscovererAudioInfo? info) {
        if (info == null) {
            return null;
        }

        return new Variant ("(ii)",
                            (int) info.get_channels (),
                            (int) info.get_sample_rate ());

    }

    private Variant? serialize_meta_data (File file,
                                          DiscovererAudioInfo? info) {
        if (info == null) {
            return null;
        }

        var tags = info.get_tags ();
        if (tags == null) {
            return null;
        }

        string artist = null;
        tags.get_string (Tags.ARTIST, out artist);

        string album = null;
        tags.get_string (Tags.ALBUM, out album);

        string genre = null;
        tags.get_string (Tags.GENRE, out genre);

        uint volume = uint.MAX;
        tags.get_uint (Tags.ALBUM_VOLUME_NUMBER, out volume);

        uint track = uint.MAX;
        tags.get_uint (Tags.TRACK_NUMBER, out track);

        uint bitrate = uint.MAX;
        tags.get_uint (Tags.BITRATE, out bitrate);

        Sample sample;
        tags.get_sample (Tags.IMAGE, out sample);
        if (sample == null) {
            tags.get_sample (Tags.PREVIEW_IMAGE, out sample);
        }

        if (sample == null) {
            try {
                if (artist != null || album != null) {
                    this.media_art.file (MediaArt.Type.ALBUM,
                                         MediaArt.ProcessFlags.NONE,
                                         file,
                                         artist,
                                         album);
                }
            } catch (Error error) {
                debug ("Failed to add external media art: %s", error.message);
            }
        } else {
            unowned Structure structure = sample.get_caps ().get_structure (0);
            int image_type;
            structure.get_enum ("image-type",
                                typeof (Gst.Tag.ImageType),
                                out image_type);
            if (image_type == Tag.ImageType.UNDEFINED ||
                image_type == Tag.ImageType.FRONT_COVER) {
                MapInfo map_info;
                sample.get_buffer ().map (out map_info, Gst.MapFlags.READ);

                // work-around for bgo#739915
                weak uint8[] data = map_info.data;
                data.length = (int) map_info.size;

                try {
                    this.media_art.buffer (MediaArt.Type.ALBUM,
                                           MediaArt.ProcessFlags.NONE,
                                           file,
                                           data,
                                           structure.get_name (),
                                           artist,
                                           album);
                } catch (Error error) {
                    debug ("Failed to add media art to cache: %s",
                           error.message);
                }
                sample.get_buffer ().unmap (map_info);
            }
        }

        return new Variant ("(msmsmsiii)",
                            artist,
                            album,
                            genre,
                            volume,
                            track,
                            ((int) bitrate) / 8);
    }
}
