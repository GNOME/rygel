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

using GUPnP;
using Gst;
using Gst.PbUtils;

/**
 * Represents MediaExport item.
 */
namespace Rygel.MediaExport.ItemFactory {
    internal errordomain ItemFactoryError {
        DESERIALIZATION,
        MISMATCH
    }

    private const string INVALID_CHARS = "()[]<>{}!@#$^&*+=|\\/\"'?~";
    private const string CONVERT_CHARS = "\t_\\.";
    private const string BLOCK_PATTERN = "%s[^%s]*%s";
    private const string[] BLOCKS = { "()", "{}", "[]", "<>" };
    private const string[] BLACKLIST = {
        "720p", "1080p", "x264", "ws", "proper", "real.repack", "repack",
        "hdtv", "pdtv", "notv", "dsr", "DVDRip", "divx", "xvid"
    };

    private const string[] VIDEO_SUFFIXES = {
        "webm", "mkv", "flv", "ogv", "ogg", "avi", "mov", "wmv", "mp4",
        "m4v", "mpeg", "mpg", "iso"
    };

    private static Regex char_remove_regex;
    private static Regex char_convert_regex;
    private static Regex space_compress_regex;
    private static Regex[] block_regexes;
    private static Regex[] blacklist_regexes;
    private static Regex[] video_suffix_regexes;

    private static bool check_variant_type (Variant v,
                                            string typestring) throws Error {
        if (!v.is_of_type (new VariantType (typestring))) {
            var msg = "Variant type mismatch, expected %s, got %s";
            throw new ItemFactoryError.DESERIALIZATION (msg,
                                                        v.get_type_string (),
                                                        typestring);
        }

        return true;
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

    static MediaObject? create_from_variant (MediaContainer parent,
                                             File           file,
                                             Variant?       v)
                                             throws Error {

        if (v == null) {
            return null;
        }

        ItemFactory.check_variant_type (v,"(smvmvmvmvmvmv)");

        Variant? upnp_class,
                 file_info,
                 dlna_profile,
                 info,
                 video_info,
                 audio_info,
                 meta_data;

        var it = v.iterator ();

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
        MediaObject object = null;
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
            case Rygel.PlaylistItem.UPNP_CLASS:
                item = ItemFactory.create_playlist_item (file, parent, "");
                break;
            case DVDContainer.UPNP_CLASS:
                object = new DVDContainer ("dvd:" + id, parent, "", file.get_path ());
                object.add_uri (file.get_uri ());

                if (file_info != null) {
                    apply_file_info (object, file_info);
                    object.title =  strip_invalid_entities (object.title);
                }

                return object;
            default:
                return null;
        }

        item.add_uri (file.get_uri ());

        if (dlna_profile != null) {
            apply_dlna_profile (item, dlna_profile);
        }

        if (info != null) {
            apply_info (item, info);
        }

        if (file_info != null) {
            apply_file_info (item, file_info);
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

    private static void apply_meta_data (MediaFileItem item, Variant v)
                                         throws Error {
        ItemFactory.check_variant_type (v, "(msmsmsiii)");

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

    private static void apply_video_info (MediaFileItem item, Variant v)
                                          throws Error {
        ItemFactory.check_variant_type (v, "(iii)");

        if (!(item is VisualItem)) {
            var msg = "UPnP class does not match supplied meta data";
            throw new ItemFactoryError.MISMATCH (msg);
        }

        var visual_item = item as VisualItem;
        var it = v.iterator ();
        visual_item.width = it.next_value ().get_int32 ();
        visual_item.height = it.next_value ().get_int32 ();
        visual_item.color_depth = it.next_value ().get_int32 ();
    }

    private static void apply_audio_info (MediaFileItem item, Variant v)
                                          throws Error {
        ItemFactory.check_variant_type (v, "(ii)");

        if (!(item is AudioItem)) {
            var msg = "UPnP class does not match supplied meta data";
            throw new ItemFactoryError.MISMATCH (msg);
        }

        var audio_item = item as AudioItem;
        var it = v.iterator ();
        audio_item.channels = it.next_value ().get_int32 ();
        audio_item.sample_freq = it.next_value ().get_int32 ();
    }

    private static void apply_info (MediaFileItem item, Variant v)
                                    throws Error {
        ItemFactory.check_variant_type (v, "(msmsi)");

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

    private static void apply_dlna_profile (MediaFileItem item, Variant v)
                                            throws Error {
        ItemFactory.check_variant_type (v, "(ss)");

        var it = v.iterator ();
        item.dlna_profile = it.next_value ().dup_string ();
        item.mime_type = it.next_value ().dup_string ();
    }

    private static void apply_file_info (MediaObject object, Variant v)
                                         throws Error {
        ItemFactory.check_variant_type (v, "(sstt)");

        var it = v.iterator ();

        Variant display_name;
        display_name = it.next_value ();
        if (object.title == null || object.title == "") {
            object.title = display_name.dup_string ();
        }

        if (object is MediaFileItem) {
            var item = object as MediaFileItem;

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

    private string strip_invalid_entities (string original) {
        if (char_remove_regex == null) {
            try {
                var regex_string = Regex.escape_string (INVALID_CHARS);
                char_remove_regex = new Regex ("[%s]".printf (regex_string));
                regex_string = Regex.escape_string (CONVERT_CHARS);
                char_convert_regex = new Regex ("[%s]".printf (regex_string));
                space_compress_regex = new Regex ("\\s+");
                block_regexes = new Regex[0];

                foreach (var block in BLOCKS) {
                    var block_re = BLOCK_PATTERN.printf (
                                      Regex.escape_string ("%C".printf (block[0])),
                                      Regex.escape_string ("%C".printf (block[1])),
                                      Regex.escape_string ("%C".printf (block[1])));
                    block_regexes += new Regex (block_re);
                }

                foreach (var blacklist in BLACKLIST) {
                    blacklist_regexes += new Regex (Regex.escape_string
                                                    (blacklist));
                }

                foreach (var suffix in VIDEO_SUFFIXES) {
                    video_suffix_regexes += new Regex (Regex.escape_string
                                                        (suffix));
                }
            } catch (RegexError error) {
                assert_not_reached ();
            }
        }

        string p;

        p = original;

        try {
            foreach (var re in blacklist_regexes) {
                p = re.replace_literal (p, -1, 0, "");
            }

            foreach (var re in video_suffix_regexes) {
                p = re.replace_literal (p, -1, 0, "");
            }

            foreach (var re in block_regexes) {
                p = re.replace_literal (p, -1, 0, "");
            }

            p = char_remove_regex.replace_literal (p, -1, 0, "");
            p = char_convert_regex.replace_literal (p, -1, 0, " ");
            p = space_compress_regex.replace_literal (p, -1, 0, " ");

            p._strip ();

            return p;
        } catch (RegexError error) {
            assert_not_reached ();
        }
    }
}
