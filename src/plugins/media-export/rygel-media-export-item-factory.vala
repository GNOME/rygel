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
using Gst;
using Gst.PbUtils;

/**
 * Represents MediaExport item.
 */
namespace Rygel.MediaExport.ItemFactory {
    public static MediaItem? create_simple (MediaContainer parent,
                                            File           file,
                                            FileInfo       info) {
        var title = info.get_display_name ();
        MediaItem item;
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

    private static MediaItem? create_playlist_item (File file,
                                                    MediaContainer parent,
                                                    string fallback_title) {
        try {
            uint8[] contents;

            if (!file.load_contents (null, out contents, null)) {
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

    public static MediaItem? create_from_info
                                        (MediaContainer        parent,
                                         File                  file,
                                         GUPnPDLNA.Information dlna_info,
                                         FileInfo              file_info) {
        MediaItem item;
        string id = MediaCache.get_id (file);
        GLib.List<DiscovererAudioInfo> audio_streams;
        GLib.List<DiscovererVideoInfo> video_streams;

        audio_streams = (GLib.List<DiscovererAudioInfo>)
                                        dlna_info.info.get_audio_streams ();
        video_streams = (GLib.List<DiscovererVideoInfo>)
                                        dlna_info.info.get_video_streams ();

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
                                    dlna_info,
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
                                    dlna_info,
                                    video_streams.data,
                                    audio_info,
                                    file_info);
        } else if (audio_streams != null) {
            item = new MusicItem (id, parent, "");
            return fill_music_item (item as MusicItem,
                                    file,
                                    dlna_info,
                                    audio_streams.data,
                                    file_info);
        } else {
            return null;
        }
    }

    private static void fill_audio_item (AudioItem             item,
                                         GUPnPDLNA.Information dlna_info,
                                         DiscovererAudioInfo?  audio_info) {
        if (dlna_info.info.get_duration () > 0) {
            item.duration = (long) (dlna_info.info.get_duration () / Gst.SECOND);
        } else {
            item.duration = -1;
        }

        if (audio_info != null) {
            if (audio_info.get_tags () != null) {
                uint tmp;
                audio_info.get_tags ().get_uint (Tags.BITRATE, out tmp);
                item.bitrate = (int) tmp / 8;
            }
            item.channels = (int) audio_info.get_channels ();
            item.sample_freq = (int) audio_info.get_sample_rate ();
        }
    }


    private static MediaItem fill_video_item (VideoItem             item,
                                              File                  file,
                                              GUPnPDLNA.Information dlna_info,
                                              DiscovererVideoInfo   video_info,
                                              DiscovererAudioInfo?  audio_info,
                                              FileInfo              file_info) {
        fill_audio_item (item as AudioItem, dlna_info, audio_info);
        fill_media_item (item, file, dlna_info, file_info);

        item.width = (int) video_info.get_width ();
        item.height = (int) video_info.get_height ();

        var color_depth = (int) video_info.get_depth ();
        item.color_depth = (color_depth == 0) ? -1 : color_depth;

        return item;
    }

    private static MediaItem fill_photo_item (PhotoItem             item,
                                              File                  file,
                                              GUPnPDLNA.Information dlna_info,
                                              DiscovererVideoInfo   video_info,
                                              FileInfo              file_info) {
        fill_media_item (item, file, dlna_info, file_info);

        item.width = (int) video_info.get_width ();
        item.height = (int) video_info.get_height ();

        var color_depth = (int) video_info.get_depth ();
        item.color_depth = (color_depth == 0) ? -1 : color_depth;

        return item;
    }

    private static MediaItem fill_music_item (MusicItem             item,
                                              File                  file,
                                              GUPnPDLNA.Information dlna_info,
                                              DiscovererAudioInfo?  audio_info,
                                              FileInfo              file_info) {
        fill_audio_item (item as AudioItem, dlna_info, audio_info);
        fill_media_item (item, file, dlna_info, file_info);

        if (audio_info == null) {
            return item;
        }
        string artist;
        dlna_info.info.get_tags ().get_string (Tags.ARTIST, out artist);
        item.artist = artist;

        string album;
        dlna_info.info.get_tags ().get_string (Tags.ALBUM, out album);
        item.album = album;

        string genre;
        dlna_info.info.get_tags ().get_string (Tags.GENRE, out genre);
        item.genre = genre;

        uint tmp;
        dlna_info.info.get_tags ().get_uint (Tags.ALBUM_VOLUME_NUMBER,
                                             out tmp);
        item.disc = (int) tmp;

        dlna_info.info.get_tags() .get_uint (Tags.TRACK_NUMBER, out tmp);
        item.track_number = (int) tmp;

        if (audio_info.get_tags () == null) {
            return item;
        }

        Sample sample;
        audio_info.get_tags ().get_sample (Tags.IMAGE, out sample);
        if (sample == null) {
            return item;
        }
        var structure = sample.get_caps ().get_structure (0);

        int image_type;
        structure.get_enum ("image-type",
                            typeof (Gst.Tag.ImageType),
                            out image_type);
        switch (image_type) {
            case Tag.ImageType.UNDEFINED:
            case Tag.ImageType.FRONT_COVER:
                var store = MediaArtStore.get_default ();
                var thumb = store.get_media_art_file ("album", item, true);
                try {
                    var writer = new JPEGWriter ();
                    writer.write (sample.get_buffer (), thumb);
                } catch (Error error) {}
                break;
            default:
                break;
        }

        return item;
    }

    private static void fill_media_item (MediaItem             item,
                                         File                  file,
                                         GUPnPDLNA.Information dlna_info,
                                         FileInfo              file_info) {
        string title = null;

        if (dlna_info.info.get_tags () == null ||
            !dlna_info.info.get_tags ().get_string (Tags.TITLE, out title)) {
            title = file_info.get_display_name ();
        }

        item.title = title;

        if (dlna_info.info.get_tags () != null) {
            GLib.Date? date;
            if (dlna_info.info.get_tags ().get_date (Tags.DATE, out date) &&
                date.valid ()) {
                char[] datestr = new char[30];
                date.strftime (datestr, "%F");
                item.date = (string) datestr;
            }
        }

        // use mtime if no time tag was available
        var mtime = file_info.get_attribute_uint64
                                        (FileAttribute.TIME_MODIFIED);

        if (item.date == null) {
            TimeVal tv = { (long) mtime, 0 };
            item.date = tv.to_iso8601 ();
        }

        item.size = (int64) file_info.get_size ();
        item.modified = (int64) mtime;
        if (dlna_info.name != null) {
            item.dlna_profile = dlna_info.name;
            item.mime_type = dlna_info.mime;
        } else {
            item.mime_type = ContentType.get_mime_type
                                        (file_info.get_content_type ());
        }

        item.add_uri (file.get_uri ());
    }
}
