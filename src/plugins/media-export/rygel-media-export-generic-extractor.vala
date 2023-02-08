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

using Gst.PbUtils;
using GUPnPDLNA;
using Gst;

internal class Rygel.MediaExport.GenericExtractor: Extractor {
    private static Discoverer discoverer;
    private static ProfileGuesser guesser;
    private static MediaArt.Process media_art;
    private string upnp_class;
    private string mime_type;

    public GenericExtractor (File file) {
        GLib.Object (file: file);
    }

    static construct {
        try {
            GenericExtractor.discoverer = new Discoverer (10 * Gst.SECOND);
            GenericExtractor.discoverer.start ();
        } catch (Error error) {
            debug ("Generic extractor unavailable: %s", error.message);
        }
        GenericExtractor.guesser = new ProfileGuesser (true, true);

        try {
            GenericExtractor.media_art = new MediaArt.Process ();
        } catch (Error error) {
            warning (_("Failed to create media art extractor: %s"),
                     error.message);
        }
    }

    public override async void run () throws Error {
        yield base.run ();

        if (GenericExtractor.discoverer == null) {
            throw new ExtractorError.GENERAL ("Backend not avaliable");
        }

        Error error = null;
        DiscovererInfo? info = null;

        var id = GenericExtractor.discoverer.discovered.connect (
            (_info, _error) => {
                info = _info;
                error = _error;
                run.callback ();
        });

        var path = this.file.get_path ();
        var uri = this.file.get_uri ();

        if (path != null) {
            uri = Filename.to_uri (path);
        }

        GenericExtractor.discoverer.discover_uri_async (uri);
        yield;
        GenericExtractor.discoverer.disconnect (id);

        if (error != null) {
            // Re-create discoverer, in error case it tends to get really
            // slow.
            GenericExtractor.discoverer.stop ();
            GenericExtractor.discoverer = null;
            GenericExtractor.discoverer = new Discoverer (10 * Gst.SECOND);
            GenericExtractor.discoverer.start ();

            var result = info.get_result ();
            if (result == DiscovererResult.TIMEOUT) {
                debug ("Extraction timed out on %s", file.get_uri ());
            } else if (result == DiscovererResult.MISSING_PLUGINS) {
                debug ("Plugins are missing for extraction of file %s",
                       file.get_uri ());
            }

            throw error;
        }

        var stream_info = info.get_stream_info ();
        Gst.TagList? stream_tags = null;

        // Guess UPnP profile
        if (stream_info is DiscovererContainerInfo) {
            stream_tags = ((DiscovererContainerInfo)stream_info).get_tags();
        } else if (stream_info is DiscovererStreamInfo) {
            stream_tags = ((DiscovererStreamInfo)stream_info).get_tags();
        }

        var audio_streams = (GLib.List<DiscovererAudioInfo>)
                                            info.get_audio_streams ();
        var video_streams = (GLib.List<DiscovererVideoInfo>)
                                            info.get_video_streams ();
        if (audio_streams == null && video_streams == null) {
            debug ("%s had neither audio nor video/picture streams. Ignoring.",
                   this.file.get_uri ());

            throw new ExtractorError.GENERAL ("No stream information");
        }

        this.upnp_class = "object.item";
        if (audio_streams == null && video_streams.data.is_image ()) {
            this.upnp_class = UPNP_CLASS_PHOTO;
        } else if (video_streams != null) {
            this.upnp_class = UPNP_CLASS_VIDEO;
        } else if (audio_streams != null) {
            this.upnp_class = UPNP_CLASS_MUSIC;
        }

        this.serialized_info.insert (Serializer.UPNP_CLASS, "s", upnp_class);

        var dlna_info = GUPnPDLNAGst.utils_information_from_discoverer_info
                                        (info);
        var dlna = GenericExtractor.guesser.guess_profile_from_info
                                        (dlna_info);

        if (dlna != null) {
            this.serialized_info.insert (Serializer.DLNA_PROFILE, "s", dlna.name);
            this.serialized_info.insert (Serializer.MIME_TYPE, "s", dlna.mime);
        }
        this.serialized_info.lookup (Serializer.MIME_TYPE, "s", out this.mime_type);

        long duration = -1;
        if (info.get_duration () > 0) {
            duration = (long) (info.get_duration () / Gst.SECOND);
            this.serialized_info.insert (Serializer.DURATION, "i", duration);
        }

        // Info has several tags, general and on audio info for music files

        // First, try the glibal tags (title, date) from the potential container,
        // if there were any
        this.get_title_and_date (stream_tags);

        if (video_streams != null && video_streams.data != null) {
            var vinfo = (DiscovererVideoInfo) video_streams.data;
            this.serialized_info.insert (Serializer.VIDEO_WIDTH, "i",
                                         (int) vinfo.get_width ());
            this.serialized_info.insert (Serializer.VIDEO_HEIGHT, "i",
                                         (int) vinfo.get_height ());
            this.serialized_info.insert (Serializer.VIDEO_DEPTH, "i",
                                         vinfo.get_depth () > 0 ?
                                         vinfo.get_depth () : -1);
        }

        if (audio_streams != null && audio_streams.data != null) {
            var ainfo = (DiscovererAudioInfo) audio_streams.data;
            if (video_streams == null && stream_tags == null) {
                // FIXME: Should be covered by the "is DiscovererStreamInfo"
                // above
                this.get_title_and_date (ainfo.get_tags ());
            }

            this.serialized_info.insert (Serializer.AUDIO_CHANNELS, "i",
                                         (int) ainfo.get_channels ());
            this.serialized_info.insert (Serializer.AUDIO_RATE, "i",
                                         (int) ainfo.get_sample_rate ());
            var atags = ainfo.get_tags ();
            if (atags != null) {
                string artist = null;
                if (atags.get_string (Tags.ARTIST, out artist) &&
                    this.mime_type != "video/x-msvideo") {
                    this.serialized_info.insert (Serializer.ARTIST, "s", artist);
                }

                string album = null;
                if (atags.get_string (Tags.ALBUM, out album)) {
                    this.serialized_info.insert (Serializer.ALBUM, "s", album);
                }

                string genre = null;
                if (atags.get_string (Tags.GENRE, out genre)) {
                    this.serialized_info.insert (Serializer.GENRE, "s", genre);
                }

                uint volume = uint.MAX;
                if (atags.get_uint (Tags.ALBUM_VOLUME_NUMBER, out volume)) {
                    this.serialized_info.insert (Serializer.VOLUME_NUMBER,
                                                 "i",
                                                 volume);
                }

                uint track = uint.MAX;
                if (atags.get_uint (Tags.TRACK_NUMBER, out track)) {
                    this.serialized_info.insert (Serializer.TRACK_NUMBER, "i", track);
                }

                uint bitrate = uint.MAX;
                if (atags.get_uint (Tags.BITRATE, out bitrate)) {
                    this.serialized_info.insert (Serializer.AUDIO_BITRATE, "i",
                                                 ((int) bitrate) / 8);
                }

                if (GenericExtractor.media_art != null) {
                    Sample sample;
                    atags.get_sample (Tags.IMAGE, out sample);
                    if (sample == null) {
                        atags.get_sample (Tags.PREVIEW_IMAGE, out sample);
                    }

                    if (sample == null) {
                        try {
                            if (artist != null || album != null) {
                                GenericExtractor.media_art.file
                                                    (MediaArt.Type.ALBUM,
                                                     MediaArt.ProcessFlags.NONE,
                                                     file,
                                                     artist,
                                                     album);
                            }
                        } catch (Error error) {
                            debug ("Failed to add external media art: %s",
                                   error.message);
                        }
                    } else {
                        var caps = sample.get_caps ();
                        unowned Structure structure = caps.get_structure (0);
                        int image_type;
                        structure.get_enum ("image-type",
                                            typeof (Gst.Tag.ImageType),
                                            out image_type);
                        if (image_type == Tag.ImageType.UNDEFINED ||
                            image_type == Tag.ImageType.FRONT_COVER) {
                            MapInfo map_info;
                            sample.get_buffer ().map (out map_info,
                                                      Gst.MapFlags.READ);

                            // work-around for bgo#739915
                            weak uint8[] data = map_info.data;
                            data.length = (int) map_info.size;

                            try {
                                GenericExtractor.media_art.buffer
                                                      (MediaArt.Type.ALBUM,
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
                }
            }
        }
    }

    private void get_title_and_date (Gst.TagList? tags) {
        if (tags == null) {
            return;
        }

        string? title = null;
        if (tags.get_string (Tags.TITLE, out title)) {
            // If not AVI file, replace title we guessed from filename
            if (this.mime_type != "video/x-msvideo" && title != null) {
                this.serialized_info.insert (Serializer.TITLE, "s", title);
            }
        }

        string date = null;
        Gst.DateTime? dt = null;
        if (tags.get_date_time (Tags.DATE_TIME, out dt)) {
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

            this.serialized_info.insert (Serializer.DATE, "s", date);
        }
    }
}
