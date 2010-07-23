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
public class Rygel.MediaExport.Item : Rygel.MediaItem {
    public Item.simple (MediaContainer parent,
                        File           file,
                        string         mime,
                        uint64         size,
                        uint64         mtime) {
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 file.get_uri ());
        var title = file.get_basename ();
        string upnp_class;

        if (mime.has_prefix ("video/")) {
            upnp_class = MediaItem.VIDEO_CLASS;
        } else if (mime.has_prefix ("image/")) {
            upnp_class = MediaItem.PHOTO_CLASS;
        } else {
            upnp_class = MediaItem.AUDIO_CLASS;
        }

        base (id, parent, title, upnp_class);
        this.mime_type = mime;
        this.size = (long) size;
        this.modified = mtime;
        this.add_uri (file.get_uri (), null);
    }

    public static Item? create_from_info (MediaContainer        parent,
                                          File                  file,
                                          GUPnP.DLNAInformation dlna_info,
                                          string                mime,
                                          uint64                size,
                                          uint64                mtime) {
        string id = Checksum.compute_for_string (ChecksumType.MD5,
                                                 file.get_uri ());
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
                return new Item.photo (parent,
                                       id,
                                       file,
                                       dlna_info,
                                       video_info,
                                       mime,
                                       size,
                                       mtime);
            } else {
                return new Item.video (parent,
                                       id,
                                       file,
                                       dlna_info,
                                       video_info,
                                       audio_info,
                                       mime,
                                       size,
                                       mtime);
            }
        } else if (audio_info != null) {
            return new Item.audio (parent,
                                   id,
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

    private Item.video (MediaContainer              parent,
                        string                      id,
                        File                        file,
                        GUPnP.DLNAInformation       dlna_info,
                        Gst.StreamVideoInformation  video_info,
                        Gst.StreamAudioInformation? audio_info,
                        string                      mime,
                        uint64                      size,
                        uint64                      mtime) {
        this (parent,
              id,
              file,
              dlna_info,
              mime,
              size,
              mtime,
              MediaItem.VIDEO_CLASS);

        this.width = (int) video_info.width;
        this.height = (int) video_info.height;
        this.color_depth = (int) video_info.depth;

        if (audio_info != null) {
            this.n_audio_channels = (int) audio_info.channels;
            this.sample_freq = (int) audio_info.sample_rate;
            if (audio_info.tags != null) {
                uint tmp;

                audio_info.tags.get_uint (TAG_BITRATE, out tmp);
                this.bitrate = (int) tmp / 8;
            }
        }
    }

    private Item.photo (MediaContainer             parent,
                        string                     id,
                        File                       file,
                        GUPnP.DLNAInformation      dlna_info,
                        Gst.StreamVideoInformation video_info,
                        string                     mime,
                        uint64                     size,
                        uint64                     mtime) {
        this (parent,
              id,
              file,
              dlna_info,
              mime,
              size,
              mtime,
              MediaItem.PHOTO_CLASS);

        this.width = (int) video_info.width;
        this.height = (int) video_info.height;
        this.color_depth = (int) video_info.depth;
    }

    private Item.audio (MediaContainer             parent,
                        string                     id,
                        File                       file,
                        GUPnP.DLNAInformation      dlna_info,
                        Gst.StreamAudioInformation audio_info,
                        string                     mime,
                        uint64                     size,
                        uint64                     mtime) {
        this (parent,
              id,
              file,
              dlna_info,
              mime,
              size,
              mtime,
              MediaItem.MUSIC_CLASS);

        if (audio_info.tags != null) {
            uint tmp;

            audio_info.tags.get_uint (TAG_BITRATE, out tmp);
            this.bitrate = (int) tmp / 8;
        }
        this.n_audio_channels = (int) audio_info.channels;
        this.sample_freq = (int) audio_info.sample_rate;
    }

    private Item (MediaContainer        parent,
                  string                id,
                  File                  file,
                  GUPnP.DLNAInformation dlna_info,
                  string                mime,
                  uint64                size,
                  uint64                mtime,
                  string                upnp_class) {
        string title = null;

        if (dlna_info.info.tags == null ||
            !dlna_info.info.tags.get_string (TAG_TITLE, out title)) {
            title = file.get_basename ();
        }

        base (id, parent, title, upnp_class);

        if (dlna_info.info.duration > 0) {
            this.duration = dlna_info.info.duration / Gst.SECOND;
        } else {
            this.duration = -1;
        }

        if (dlna_info.info.tags != null) {
            dlna_info.info.tags.get_string (TAG_ARTIST, out this.author);
            dlna_info.info.tags.get_string (TAG_ALBUM, out this.album);

            uint tmp;
            dlna_info.info.tags.get_uint (TAG_TRACK_NUMBER, out tmp);
            this.track_number = (int) tmp;

            GLib.Date? date;
            if (dlna_info.info.tags.get_date (TAG_DATE, out date)) {
                char[] datestr = new char[30];
                date.strftime (datestr, "%F");
                this.date = (string) datestr;
            } else {
                TimeVal tv = { (long) mtime, 0 };
                this.date = tv.to_iso8601 ();
            }
        }

        this.size = (long) size;
        this.modified = (int64) mtime;

        if (dlna_info.name != null) {
            this.dlna_profile = dlna_info.name;
            this.mime_type = dlna_info.mime;
        } else {
            this.mime_type = mime;
        }

        this.add_uri (file.get_uri (), null);
    }
}

