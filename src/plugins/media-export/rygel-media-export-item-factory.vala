/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2012,2013 Intel Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
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
using Gst;
using Gst.PbUtils;

/**
 * Represents MediaExport item.
 */
namespace Rygel.MediaExport.ItemFactory {
    public static MediaFileItem? create_simple (MediaContainer parent,
                                                File           file,
                                                FileInfo       info) {
        var title = info.get_display_name ();
        MediaFileItem item;
        var mime = ContentType.get_mime_type (info.get_content_type ());

        if (mime.has_prefix ("video/")) {
            item = new VideoItem (MediaCache.get_id (file), parent, title);
        } else if (mime.has_prefix ("image/")) {
            item = new PhotoItem (MediaCache.get_id (file), parent, title);
        } else if (mime.has_prefix ("audio/") || mime == "application/ogg") {
            item = new MusicItem (MediaCache.get_id (file), parent, title);
        } else { // application/xml or text/xml
            item = ItemFactory.create_playlist_item (file, parent, title);
            if (item == null) {
                return null;
            }
            // DLNA requires that DIDL_S playlist have text/xml MIME type.
            mime = "text/xml";
        }

        item.mime_type = mime;
        item.size = (int64) info.get_size ();
        item.modified = info.get_attribute_uint64
                                        (FileAttribute.TIME_MODIFIED);
        item.add_uri (file.get_uri ());

        return item;
    }

    private static MediaFileItem? create_playlist_item (File file,
                                                        MediaContainer parent,
                                                        string fallback_title) {
        try {
            uint8[] contents;

            if (!file.load_contents (null, out contents, null)) {
                return null;
            }

            /* Do some heuristic check if this file looks like XML */
            var i = 0;
            while (((char) contents[i]).isspace () && i < contents.length) {
                i++;
            }

            if (contents[i] != '<') {
                return null;
            }

            var didl_s = new MediaCollection.from_string ((string) contents);
            var author = didl_s.author;
            var title = didl_s.title;

            if (author == null &&
                title == null &&
                didl_s.get_items () == null) {
                return null;
            }

            if (title == null) {
                title = fallback_title;
            }

            var item = new PlaylistItem (MediaCache.get_id (file),
                                         parent,
                                         title);

            if (author != null) {
                item.creator = author;
            }

            item.dlna_profile = "DIDL_S";

            return item;
        } catch (Error e) {
            return null;
        }
    }

    public static MediaFileItem? create_from_info (MediaContainer     parent,
                                                   File               file,
                                                   DiscovererInfo     info,
                                                   GUPnPDLNA.Profile? profile,
                                                   FileInfo           file_info) {
        MediaFileItem item;
        string id = MediaCache.get_id (file);
        GLib.List<DiscovererAudioInfo> audio_streams;
        GLib.List<DiscovererVideoInfo> video_streams;

        audio_streams = (GLib.List<DiscovererAudioInfo>)
                                        info.get_audio_streams ();
        video_streams = (GLib.List<DiscovererVideoInfo>)
                                        info.get_video_streams ();

        if (audio_streams == null && video_streams == null) {
            debug ("%s had neither audio nor video/picture " +
                   "streams. Ignoring.",
                   file.get_uri ());

            return null;
        }

        if (audio_streams == null && video_streams.data.is_image()) {
            item = new PhotoItem (id, parent, "");
            return fill_photo_item (item as PhotoItem,
                                    file,
                                    info,
                                    profile,
                                    video_streams.data,
                                    file_info);
        } else if (video_streams != null) {
            item = new VideoItem (id, parent, "");

            var audio_info = null as DiscovererAudioInfo;
            if (audio_streams != null) {
                audio_info = audio_streams.data;
            }

            return fill_video_item (item as VideoItem,
                                    file,
                                    info,
                                    profile,
                                    video_streams.data,
                                    audio_info,
                                    file_info);
        } else if (audio_streams != null) {
            item = new MusicItem (id, parent, "");
            return fill_music_item (item as MusicItem,
                                    file,
                                    info,
                                    profile,
                                    audio_streams.data,
                                    file_info);
        } else {
            return null;
        }
    }

    private static void fill_audio_item (AudioItem            item,
                                         DiscovererInfo       info,
                                         DiscovererAudioInfo? audio_info) {
        if (info.get_duration () > 0) {
            item.duration = (long) (info.get_duration () / Gst.SECOND);
        } else {
            item.duration = -1;
        }

        if (audio_info == null)
            return;
  
        var tags = audio_info.get_tags ();
        if (tags != null) {
          uint tmp;
          tags.get_uint (Tags.BITRATE, out tmp);
          item.bitrate = (int) tmp / 8;
        }
        
        item.channels = (int) audio_info.get_channels ();
        item.sample_freq = (int) audio_info.get_sample_rate ();
    }


    private static MediaFileItem fill_video_item (VideoItem            item,
                                                  File                 file,
                                                  DiscovererInfo       info,
                                                  GUPnPDLNA.Profile?   profile,
                                                  DiscovererVideoInfo  video_info,
                                                  DiscovererAudioInfo? audio_info,
                                                  FileInfo             file_info) {
        fill_audio_item (item as AudioItem, info, audio_info);
        fill_media_item (item, file, info, profile, file_info);

        item.width = (int) video_info.get_width ();
        item.height = (int) video_info.get_height ();

        var color_depth = (int) video_info.get_depth ();
        item.color_depth = (color_depth == 0) ? -1 : color_depth;

        return item;
    }

    private static MediaFileItem fill_photo_item (PhotoItem           item,
                                                  File                file,
                                                  DiscovererInfo      info,
                                                  GUPnPDLNA.Profile?  profile,
                                                  DiscovererVideoInfo video_info,
                                                  FileInfo            file_info) {
        fill_media_item (item, file, info, profile, file_info);

        item.width = (int) video_info.get_width ();
        item.height = (int) video_info.get_height ();

        var color_depth = (int) video_info.get_depth ();
        item.color_depth = (color_depth == 0) ? -1 : color_depth;

        return item;
    }

    private static MediaFileItem fill_music_item (MusicItem            item,
                                                  File                 file,
                                                  DiscovererInfo       info,
                                                  GUPnPDLNA.Profile?   profile,
                                                  DiscovererAudioInfo? audio_info,
                                                  FileInfo             file_info) {
        fill_audio_item (item as AudioItem, info, audio_info);
        fill_media_item (item, file, info, profile, file_info);

        if (audio_info == null) {
            return item;
        }
        
        var tags = audio_info.get_tags ();
        if (tags == null) {
            return item;
        }
        
        string artist;
        tags.get_string (Tags.ARTIST, out artist);
        item.artist = artist;

        string album;
        tags.get_string (Tags.ALBUM, out album);
        item.album = album;

        string genre;
        tags.get_string (Tags.GENRE, out genre);
        item.genre = genre;

        uint tmp;
        tags.get_uint (Tags.ALBUM_VOLUME_NUMBER, out tmp);
        item.disc = (int) tmp;

        tags.get_uint (Tags.TRACK_NUMBER, out tmp);
        item.track_number = (int) tmp;


        var store = MediaArtStore.get_default ();

        Sample sample;
        tags.get_sample (Tags.IMAGE, out sample);
        if (sample == null) {
            tags.get_sample (Tags.PREVIEW_IMAGE, out sample);
        }

        if (sample == null) {
            store.search_media_art_for_file (item, file);

            return item;
        }

        unowned Structure structure = sample.get_caps ().get_structure (0);

        int image_type;
        structure.get_enum ("image-type",
                            typeof (Gst.Tag.ImageType),
                            out image_type);
        switch (image_type) {
            case Tag.ImageType.UNDEFINED:
            case Tag.ImageType.FRONT_COVER:
                Gst.MapInfo map_info;
                sample.get_buffer ().map (out map_info, Gst.MapFlags.READ);

                // Work-around bgo#739915
                weak uint8[] data = map_info.data;
                data.length = (int) map_info.size;

                store.add (item, file, data, structure.get_name ());
                sample.get_buffer ().unmap (map_info);
                break;
            default:
                break;
        }

        return item;
    }

    private static void fill_media_item (MediaFileItem      item,
                                         File               file,
                                         DiscovererInfo     info,
                                         GUPnPDLNA.Profile? profile,
                                         FileInfo           file_info) {
        string title = null;

        var tags = info.get_tags ();
        if (tags == null ||
            !tags.get_string (Tags.TITLE, out title)) {
            title = file_info.get_display_name ();

        }

        // This assumes the datetime is valid; checking some demuxers this
        Gst.DateTime? dt = null;
        if (tags != null && tags.get_date_time (Tags.DATE_TIME, out dt)) {
            // Make a minimal valid iso8601 date - bgo#702231
            // This mostly happens with MP3 files which only have a year
            if (!dt.has_day () || !dt.has_month ()) {
                item.date = "%d-%02d-%02d".printf (dt.get_year (),
                                                   dt.has_month () ?
                                                       dt.get_month () : 1,
                                                   dt.has_day () ?
                                                       dt.get_day () : 1);
            } else {
                item.date = dt.to_iso8601_string ();
            }
        }

        item.title = title;

        // use mtime if no time tag was available
        var mtime = file_info.get_attribute_uint64
                                        (FileAttribute.TIME_MODIFIED);

        if (item.date == null) {
            TimeVal tv = { (long) mtime, 0 };
            item.date = tv.to_iso8601 ();
        }

        // If the date has a timezone offset, make sure it contains a
        // colon bgo#702231, DLNA 7.3.21.1
        if ("T" in item.date) {
            var date = new Soup.Date.from_string (item.date);
            item.date = date.to_string (Soup.DateFormat.ISO8601_FULL);
        }

        item.size = (int64) file_info.get_size ();
        item.modified = (int64) mtime;
        if (profile != null && profile.name != null) {
            item.dlna_profile = profile.name;
            item.mime_type = profile.mime;
        } else {
            item.mime_type = ContentType.get_mime_type
                                        (file_info.get_content_type ());
        }

        item.add_uri (file.get_uri ());
    }
}
