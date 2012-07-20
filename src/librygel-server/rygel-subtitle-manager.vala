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

internal errordomain SubtitleManagerError {
    NO_SUBTITLE
}

/**
 * Provides subtitles for vidoes.
 */
internal class Rygel.SubtitleManager : GLib.Object {
    private static SubtitleManager manager; // Our singleton object

    public static SubtitleManager? get_default () {
        if (manager == null) {
            manager = new SubtitleManager ();
        }

        return manager;
    }

    public Subtitle get_subtitle (string uri) throws Error {
        var video_file = File.new_for_uri (uri);

        var directory = video_file.get_parent ();
        var filename = video_file.get_basename ();
        var ext_index = filename.last_index_of_char ('.');
        if (ext_index >= 0) {
            filename = filename[0:ext_index];
        }
        // FIXME: foreach ".eng.srt", ".ger.srt", ".srt"...
        // FIXME: case insensitive?
        filename += ".srt";

        var srt_file = directory.get_child (filename);

        var info = srt_file.query_info (FileAttribute.ACCESS_CAN_READ + "," +
                                        FileAttribute.STANDARD_SIZE,
                                        FileQueryInfoFlags.NONE,
                                        null);

        if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)) {
            throw new SubtitleManagerError.NO_SUBTITLE
                                        (_("No subtitle available"));
        }

        var subtitle = new Subtitle ();
        subtitle.uri = srt_file.get_uri ();
        subtitle.size = (int64) info.get_attribute_uint64
                                        (FileAttribute.STANDARD_SIZE);

        return subtitle;
    }
}
