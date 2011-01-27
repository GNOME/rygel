/*
 * Copyright (C) 2011 Jens Georg
 *
 * Author: Jens Georg <mail@jensge.org>
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

using Gee;
using Soup;

internal class Rygel.Mediathek.MovPlaylistParser : PlaylistParser {
    public MovPlaylistParser (Session session) {
        Object (session         : session,
                playlist_suffix : ".mov",
                mime_type       : "video/mp4");
    }

    public override Gee.List<string>? parse_playlist (string data,
                                                      int    length)
                                                      throws VideoItemError {
        var lines = data.split ("\n");
        if (lines.length < 2) {
            throw new VideoItemError.XML_PARSE_ERROR
                                        ("Not enough entries in playlist");
        }

        if (lines[0] != "RTSPtext") {
            throw new VideoItemError.XML_PARSE_ERROR ("Invalid playlist format");
        }

        if (!lines[1].has_prefix ("rtsp")) {
            throw new VideoItemError.XML_PARSE_ERROR
                                        ("No rtsp url found in playlist");
        }

        var list = new ArrayList<string> ();
        list.add (lines[1]);

        return list;
    }
}
