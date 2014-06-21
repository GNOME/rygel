/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009,2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

/**
 * Creates item for external plugins.
 */
public class Rygel.External.ItemFactory {
    public async MediaFileItem create (string                    id,
                                       string                    type,
                                       string                    title,
                                       HashTable<string,Variant> props,
                                       string                    service_name,
                                       MediaContainer            parent)
                                       throws IOError, DBusError {
        MediaFileItem item;

        if (type.has_prefix ("music") ||
            type.has_prefix ("audio.music")) {
            item = new MusicItem (id, parent, title);

            yield this.set_music_metadata (item as MusicItem,
                                           props,
                                           service_name);
        } else if (type.has_prefix ("audio")) {
            item = new AudioItem (id, parent, title);

            this.set_audio_metadata (item as AudioItem, props, service_name);
        } else  if (type.has_prefix ("video")) {
            item = new VideoItem (id, parent, title);

            yield this.set_video_metadata (item as VideoItem,
                                           props,
                                           service_name);
        } else {
            item = new ImageItem (id, parent, title);

            yield this.set_visual_metadata (item as VisualItem,
                                            props,
                                            service_name);
        }

        this.set_generic_metadata (item, props, service_name);

        if (parent is DummyContainer) {
            item.parent_ref = parent;
        }

        return item;
    }

    private async void set_music_metadata
                                        (MusicItem                 music,
                                         HashTable<string,Variant> props,
                                         string                    service_name)
                                         throws IOError, DBusError {
        music.artist = this.get_string (props, "Artist");
        music.album = this.get_string (props, "Album");
        music.genre = this.get_string (props, "Genre");
        music.track_number = this.get_int (props, "TrackNumber");

        var value = props.lookup ("AlbumArt");
        if (value != null) {
            var cover_factory = new AlbumArtFactory ();

            music.album_art = yield cover_factory.create (service_name,
                                                          (string) value);
        }

        this.set_audio_metadata (music, props, service_name);
    }

    private void set_audio_metadata (AudioItem                 audio,
                                     HashTable<string,Variant> props,
                                     string                    service_name)
                                     throws DBusError {
        audio.duration = this.get_int (props, "Duration");
        audio.bitrate = this.get_int (props, "Bitrate");
        audio.sample_freq = this.get_int (props, "SampleRate");
        audio.bits_per_sample = this.get_int (props, "BitsPerSample");
    }

    private async void set_visual_metadata
                                        (VisualItem                visual,
                                         HashTable<string,Variant> props,
                                         string                    service_name)
                                         throws IOError, DBusError {
        visual.width = this.get_int (props, "Width");
        visual.height = this.get_int (props, "Height");
        visual.color_depth = this.get_int (props, "ColorDepth");

        var value = props.lookup ("Thumbnail");
        if (value != null) {
            var factory = new ThumbnailFactory ();
            var thumbnail = yield factory.create ((string) value, service_name);

            visual.thumbnails.add (thumbnail);
        }
    }

    private async void set_video_metadata
                                        (VideoItem                 video,
                                         HashTable<string,Variant> props,
                                         string                    service_name)
                                         throws IOError, DBusError {
        yield this.set_visual_metadata (video, props, service_name);
        this.set_audio_metadata (video, props, service_name);
    }

    private void set_generic_metadata (MediaFileItem             item,
                                       HashTable<string,Variant> props,
                                       string                    service_name) {
        item.mime_type = get_mandatory_string_value (props,
                                                     "MIMEType",
                                                     "image/jpeg",
                                                     service_name);
        var uris = get_mandatory_string_list_value (props,
                                                    "URLs",
                                                    null,
                                                    service_name);
        if (uris != null) {
            for (var i = 0; uris[i] != null; i++) {
                item.add_uri (uris[i]);
            }
        }

        // Optional properties

        item.dlna_profile = this.get_string (props, "DLNAProfile");

        var value = props.lookup ("Size");
        if (value != null) {
            item.size = (int64) value;
        }

        item.date = this.get_string (props, "Date");
    }

    private string? get_string (HashTable<string,Variant> props, string prop) {
        var value = props.lookup (prop);

        if (value != null) {
            return (string) value;
        } else {
            return null;
        }
    }

    private int get_int (HashTable<string,Variant> props, string prop) {
        var value = props.lookup (prop);

        if (value != null) {
            return (int) value;
        } else {
            return -1;
        }
    }
}

