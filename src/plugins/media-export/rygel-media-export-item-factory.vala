/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2012,2013 Intel Corporation.
 * Copyright (C) 2015 Jens Georg
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
 *         Jens Georg <jensg@openismus.com>
 *         Jens Georg <mail@jensge.org>
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
        item.modified = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
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

    static MediaFileItem? create_from_variant (MediaContainer parent,
                                               File           file,
                                               Variant        v) {
        if (!v.is_of_type (new VariantType ("(smvmvmvmvmvmv)"))) {
            warning (_("Invalid metadata serialisation, cannot process %s"),
                     v.get_type_string ());

            return null;
        }

        Variant? upnp_class,
                 file_info,
                 dlna_profile,
                 info,
                 video_info,
                 audio_info,
                 meta_data;

        var it = v.iterator ();
        if (it.n_children () != 7) {
            warning (ngettext("Invalid metadata serialisation: expected 7 children, got %d",
                              "Invalid metadata serialisation: expected 7 children, got %d",
                              (int) it.n_children ()),
                     (int) it.n_children ());

            return null;
        }

        var id = MediaCache.get_id (file);

        upnp_class = it.next_value ();

        file_info = it.next_value ().get_maybe ();
        if (file_info != null) {
            file_info = file_info.get_variant ();
        }

        dlna_profile = it.next_value ().get_maybe ();
        if (dlna_profile != null) {
            dlna_profile = dlna_profile.get_variant ();
        }

        info = it.next_value ().get_maybe ();
        if (info != null) {
            info = info.get_variant ();
        }

        audio_info = it.next_value ().get_maybe ();
        if (audio_info != null) {
            audio_info = audio_info.get_variant ();
        }

        video_info = it.next_value ().get_maybe ();
        if (video_info != null) {
            video_info = video_info.get_variant ();
        }

        meta_data = it.next_value ().get_maybe ();
        if (meta_data != null) {
            meta_data = meta_data.get_variant ();
        }

        MediaFileItem item = null;
        switch (upnp_class.get_string ()) {
            case Rygel.PhotoItem.UPNP_CLASS:
                item = new PhotoItem (id, parent, "");
                break;
            case Rygel.VideoItem.UPNP_CLASS:
                item = new VideoItem (id, parent, "");
                break;
            case Rygel.MusicItem.UPNP_CLASS:
                item = new MusicItem (id, parent, "");
                break;
            default:
                return null;
        }

        item.add_uri (file.get_uri ());

        if (dlna_profile != null) {
            apply_dlna_profile (item, dlna_profile);
        }

        if (file_info != null) {
            apply_file_info (item, file_info);
        }

        if (info != null) {
            apply_info (item, info);
        }

        if (audio_info != null) {
            apply_audio_info (item, audio_info);
        }

        if (video_info != null) {
            apply_video_info (item, video_info);
        }

        if (meta_data != null) {
            apply_meta_data (item, meta_data);
        }

        // If the date has a timezone offset, make sure it contains a
        // colon bgo#702231, DLNA 7.3.21.1
        if ("T" in item.date) {
            var date = new Soup.Date.from_string (item.date);
            item.date = date.to_string (Soup.DateFormat.ISO8601_FULL);
        }

        return item as MediaFileItem;
    }

    private static void apply_meta_data (MediaFileItem item, Variant v) {
        if (!v.is_of_type (new VariantType ("(msmsmsiii)"))) {
            warning (_("Invalid metadata serialisation of metadata; %s"),
                     v.get_type_string ());

            return;
        }

        var it = v.iterator ();
        var val = it.next_value ().get_maybe ();
        item.artist = val == null ? null : val.dup_string ();

        // Audio item
        val = it.next_value ().get_maybe (); // album
        var album = val == null ? null : val.dup_string ();

        val = it.next_value ().get_maybe ();
        item.genre = val == null ? null : val.dup_string ();

        // Audio item
        var disc = it.next_value ().get_int32 ();

        if (item is AudioItem) {
            var audio_item = item as AudioItem;
            var track_number = it.next_value ().get_int32 ();
            audio_item.bitrate = it.next_value ().get_int32 ();
            audio_item.album = album;

            if (item is MusicItem) {
                var music_item = item as MusicItem;
                music_item.disc = disc;
                music_item.track_number = track_number;
            }
        }
    }

    private static void apply_video_info (MediaFileItem item, Variant v) {
        if (!v.is_of_type (new VariantType ("(iii)"))) {
            warning (_("Invalid metadata serialisation of video info; %s"),
                     v.get_type_string ());

            return;
        }

        if (!(item is VisualItem)) {
            return;
        }

        var visual_item = item as VisualItem;
        var it = v.iterator ();
        visual_item.width = it.next_value ().get_int32 ();
        visual_item.height = it.next_value ().get_int32 ();
        visual_item.color_depth = it.next_value ().get_int32 ();
    }

    private static void apply_audio_info (MediaFileItem item, Variant v) {
        if (!v.is_of_type (new VariantType ("(ii)"))) {
            warning (_("Invalid metadata serialisation of audio info; %s"),
                     v.get_type_string ());

            return;
        }

        if (!(item is AudioItem)) {
            return;
        }

        var audio_item = item as AudioItem;
        var it = v.iterator ();
        audio_item.channels = it.next_value ().get_int32 ();
        audio_item.sample_freq = it.next_value ().get_int32 ();
    }

    private static void apply_info (MediaFileItem item, Variant v) {
        if (!v.is_of_type (new VariantType ("(msmsi)"))) {
            warning (_("Invalid metadata serialisation of general info"));
        }

        var it = v.iterator ();
        var val = it.next_value ().get_maybe ();
        if (val != null) {
            item.title = val.dup_string ();
        }

        val = it.next_value ().get_maybe ();
        if (val != null) {
            item.date = val.dup_string ();
        }

        if (item is AudioItem) {
            (item as AudioItem).duration = it.next_value ().get_int32 ();
        }
    }

    private static void apply_dlna_profile (MediaFileItem item, Variant v) {
        if (!v.is_of_type (new VariantType ("(ss)"))) {
            warning (_("Invalid metadata serialisation of DLNA profile %s"),
                     v.get_type_string ());

            return;
        }

        var it = v.iterator ();
        item.dlna_profile = it.next_value ().dup_string ();
        item.mime_type = it.next_value ().dup_string ();
    }

    private static void apply_file_info (MediaFileItem item, Variant v) {
        if (!v.is_of_type (new VariantType ("(sstt)"))) {
            warning (_("Invalid metadata serialisation of file info %s"),
                     v.get_type_string ());

            return;
        }

        var it = v.iterator ();
        if (it.n_children () != 4) {
            warning (_("Invalid metadata serialisation of file info"));

            return;
        }

        Variant display_name;
        display_name = it.next_value ();
        if (item.title == null || item.title == "") {
            item.title = display_name.dup_string ();
        }

        var mime = it.next_value ();
        if (item.mime_type == null) {
            item.mime_type = mime.dup_string ();
        }

        item.modified = (int64) it.next_value ().get_uint64 ();
        if (item.date == null) {
            TimeVal tv = { (long) item.modified, 0 };
            item.date = tv.to_iso8601 ();
        }
        item.size = (int64) it.next_value ().get_uint64 ();
    }
}
