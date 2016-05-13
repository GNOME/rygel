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

public errordomain ExtractorError {
    GENERAL,
    INVALID
}

public class Rygel.MediaExport.Extractor : Object {
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

    public File file { get; construct set; }

    protected VariantDict serialized_info;

    public Extractor (File file) {
        Object (file: file);
    }

    public override void constructed () {
        this.serialized_info = new VariantDict ();
    }

    public virtual async void run () throws Error {
        var file_info = yield file.query_info_async (FileAttribute.STANDARD_TYPE + "," +
                                                     FileAttribute.STANDARD_CONTENT_TYPE
                                                 + "," +
                                                 FileAttribute.STANDARD_SIZE + "," +
                                                 FileAttribute.TIME_MODIFIED + "," +
                                                 FileAttribute.STANDARD_DISPLAY_NAME,
                                                 FileQueryInfoFlags.NONE);
        var display_name = file_info.get_display_name ();
        this.serialized_info.insert ("DisplayName", "s", display_name);

        var title = this.strip_invalid_entities (display_name);
        this.serialized_info.insert ("Title", "s", title);

        this.serialized_info.insert ("MTime", "t", file_info.get_attribute_uint64
                                        (FileAttribute.TIME_MODIFIED));
        var content_type = ContentType.get_mime_type
                                        (file_info.get_content_type ());
        this.serialized_info.insert ("MimeType", "s", content_type);
        this.serialized_info.insert ("Size", "t", file_info.get_size ());
     }

    public new Variant? @get () {
        return this.serialized_info.end ();
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
