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

/**
 * Represents MediaExport item.
 */
namespace Rygel.MediaExport.ItemFactory {
    public static MediaItem create_simple (MediaContainer parent,
                                           File           file,
                                           string         mime,
                                           uint64         size,
                                           uint64         mtime) {
        var title = file.get_basename ();
        MediaItem item;

        if (mime.has_prefix ("video/")) {
            item = new VideoItem (MediaCache.get_id (file), parent, title);
        } else if (mime.has_prefix ("image/")) {
            item = new PhotoItem (MediaCache.get_id (file), parent, title);
        } else {
            item = new MusicItem (MediaCache.get_id (file), parent, title);
        }

        item.mime_type = mime;
        item.size = (int64) size;
        item.modified = mtime;
        item.add_uri (file.get_uri ());

        return item;
    }

    public static MediaItem? create_from_info (MediaContainer        parent,
                                               File                  file,
                                               GUPnP.DLNAInformation dlna_info,
                                               string                mime,
                                               uint64                size,
                                               uint64                mtime) {
        MediaItem item;
        string id = MediaCache.get_id (file);
        unowned StreamAudioInformation audio_info = null;
        unowned StreamVideoInformation video_info = null;

        foreach (unowned StreamInformation stream_info in
                 dlna_info.info.stream_list) {
            if (audio_info == null &&
                stream_info.streamtype == Gst.StreamType.AUDIO) {
                audio_info = (StreamAudioInformation) stream_info;
            } else if (video_info == null &&
                       (stream_info.streamtype == Gst.StreamType.VIDEO ||
                        stream_info.streamtype == Gst.StreamType.IMAGE)) {
                video_info = (StreamVideoInformation) stream_info;
            }
        }

        if (video_info != null) {
            if (audio_info == null &&
                video_info.streamtype == Gst.StreamType.IMAGE) {
                item = new PhotoItem (id, parent, "");
                return fill_photo_item (item as PhotoItem,
                                        file,
                                        dlna_info,
                                        video_info,
                                        mime,
                                        size,
                                        mtime);
            } else {
                item = new VideoItem (id, parent, "");
                return fill_video_item (item as VideoItem,
                                      file,
                                      dlna_info,
                                      video_info,
                                      audio_info,
                                      mime,
                                      size,
                                      mtime);
            }
        } else if (audio_info != null) {
            item = new MusicItem (id, parent, "");
            return fill_music_item (item as MusicItem,
                                    file,
                                    dlna_info,
                                    audio_info,
                                    mime,
                                    size,
                                    mtime);
        } else {
            return null;
        }
    }

    private static void fill_audio_item (AudioItem               item,
                                         DLNAInformation         dlna_info,
                                         StreamAudioInformation? audio_info) {
        if (dlna_info.info.duration > 0) {
            item.duration = dlna_info.info.duration / Gst.SECOND;
        } else {
            item.duration = -1;
        }


         if (audio_info != null) {
            if (audio_info.tags != null) {
                 uint tmp;
                audio_info.tags.get_uint (TAG_BITRATE, out tmp);
                item.bitrate = (int) tmp / 8;
            }
            item.channels = (int) audio_info.channels;
            item.sample_freq = (int) audio_info.sample_rate;
        }
    }


    private static MediaItem fill_video_item (VideoItem               item,
                                       File                    file,
                                       DLNAInformation         dlna_info,
                                       StreamVideoInformation  video_info,
                                       StreamAudioInformation? audio_info,
                                       string                  mime,
                                       uint64                  size,
                                       uint64                  mtime) {
        fill_audio_item (item as AudioItem, dlna_info, audio_info);
        fill_media_item (item, file, dlna_info, mime, size, mtime);

        item.width = (int) video_info.width;
        item.height = (int) video_info.height;
        item.color_depth = (int) video_info.depth;

        if (audio_info != null) {
            item.channels = (int) audio_info.channels;
            item.sample_freq = (int) audio_info.sample_rate;
            if (audio_info.tags != null) {
                uint tmp;

                audio_info.tags.get_uint (TAG_BITRATE, out tmp);
                item.bitrate = (int) tmp / 8;
            }
        }

        return item;
    }

    private static MediaItem fill_photo_item (PhotoItem              item,
                                       File                   file,
                                       DLNAInformation        dlna_info,
                                       StreamVideoInformation video_info,
                                       string                 mime,
                                       uint64                 size,
                                       uint64                 mtime) {
        fill_media_item (item,
                         file,
                         dlna_info,
                         mime,
                         size,
                         mtime);

        item.width = (int) video_info.width;
        item.height = (int) video_info.height;
        item.color_depth = (int) video_info.depth;

        return item;
    }

    private static MediaItem fill_music_item (MusicItem              item,
                                       File                   file,
                                       DLNAInformation        dlna_info,
                                       StreamAudioInformation? audio_info,
                                       string                 mime,
                                       uint64                 size,
                                       uint64                 mtime) {
        fill_audio_item (item as AudioItem, dlna_info, audio_info);
        fill_media_item (item,
                         file,
                         dlna_info,
                         mime,
                         size,
                         mtime);

        if (audio_info != null) {
            if (audio_info.tags != null) {
                unowned Gst.Buffer buffer;
                audio_info.tags.get_buffer (TAG_IMAGE, out buffer);
                if (buffer != null) {
                    var structure = buffer.caps.get_structure (0);
                    int image_type;
                    structure.get_enum ("image-type",
                            typeof (Gst.TagImageType),
                            out image_type);
                    switch (image_type) {
                        case TagImageType.UNDEFINED:
                        case TagImageType.FRONT_COVER:
                            var store = MediaArtStore.get_default ();
                            var thumb = store.get_media_art_file ("album",
                                    item,
                                    true);
                            try {
                                var writer = new JPEGWriter ();
                                writer.write (buffer, thumb);
                            } catch (Error error) {}
                            break;
                        default:
                            break;
                    }
                }
            }
            dlna_info.info.tags.get_string (TAG_ARTIST, out item.artist);
            dlna_info.info.tags.get_string (TAG_ALBUM, out item.album);
            dlna_info.info.tags.get_string (TAG_GENRE, out item.genre);

            uint tmp;
            dlna_info.info.tags.get_uint (TAG_TRACK_NUMBER, out tmp);
            item.track_number = (int) tmp;
        }

        return item;
    }

    private static void fill_media_item (MediaItem       item,
                                       File                   file,
                                  DLNAInformation dlna_info,
                                  string           mime,
                                  uint64           size,
                                  uint64           mtime) {
        string title = null;

        if (dlna_info.info.tags == null ||
            !dlna_info.info.tags.get_string (TAG_TITLE, out title)) {
            title = file.get_basename ();
        }

        item.title = title;

        if (dlna_info.info.tags != null) {
            GLib.Date? date;
            if (dlna_info.info.tags.get_date (TAG_DATE, out date)) {
                char[] datestr = new char[30];
                date.strftime (datestr, "%F");
                item.date = (string) datestr;
            }
        }

        // use mtime if no time tag was available
        if (item.date == null) {
            TimeVal tv = { (long) mtime, 0 };
            item.date = tv.to_iso8601 ();
        }

        item.size = (int64) size;
        item.modified = (int64) mtime;

        if (dlna_info.name != null) {
            item.dlna_profile = dlna_info.name;
            item.mime_type = dlna_info.mime;
        } else {
            item.mime_type = mime;
        }

        item.add_uri (file.get_uri ());
    }
}

