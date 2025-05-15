/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010 Andreas Henriksson <andreas@fatal.se>.
 *
 * Authors: Andreas Henriksson <andreas@fatal.se>
 *          Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

using Gee;

internal errordomain SubtitleManagerError {
    NO_SUBTITLE
}

/**
 * Provides subtitles for videos.
 */
internal class Rygel.SubtitleManager : GLib.Object {
    private static SubtitleManager manager; // Our singleton object

    public static SubtitleManager? get_default () {
        if (manager == null) {
            manager = new SubtitleManager ();
        }

        return manager;
    }

    public ArrayList<Subtitle> get_subtitles (string uri) throws Error {
        var video_file = File.new_for_uri (uri);
        if (!video_file.is_native ()) {
            throw new SubtitleManagerError.NO_SUBTITLE
                                        (_("No subtitle available"));
        }

        var directory = video_file.get_parent ();
        var basename = video_file.get_basename ();
        var ext_index = basename.last_index_of_char ('.');
        if (ext_index >= 0) {
            basename = basename[0:ext_index];
        }

        // FIXME: foreach ".eng.srt", ".ger.srt", ".srt"...
        // FIXME: case insensitive?
        string[] exts = { "srt", "smi", "ssa" };

        var subtitles = new ArrayList<Subtitle> ();
        foreach (string ext in exts) {
            string filename = basename + "." + ext;

            var subtitle_file = directory.get_child (filename);

            try {
                var attribs = FileAttribute.ACCESS_CAN_READ + "," +
                              FileAttribute.STANDARD_SIZE + "," +
                              FileAttribute.STANDARD_CONTENT_TYPE;

                var info = subtitle_file.query_info (attribs,
                                                     FileQueryInfoFlags.NONE,
                                                     null);

                if (info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)) {
                    var content_type = info.get_attribute_string
                                        (FileAttribute.STANDARD_CONTENT_TYPE);
                    var subtitle = new Subtitle (content_type, ext);
                    subtitle.uri = subtitle_file.get_uri ();
                    subtitle.size = (int64) info.get_attribute_uint64
                                        (FileAttribute.STANDARD_SIZE);
                    subtitles.add (subtitle);
                }
            } catch (Error err) {
                debug ("Failed to query file information for %s: %s",
                       subtitle_file.get_path (),
                       err.message);
            }
        }

        if (subtitles.size == 0) {
            throw new SubtitleManagerError.NO_SUBTITLE
                                        (_("No subtitle available"));
        }

        return subtitles;
    }
}
