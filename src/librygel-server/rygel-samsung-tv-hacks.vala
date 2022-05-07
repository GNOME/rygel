/*
 * Copyright (C) 2012 Choe Hwanjin <choe.hwanjin@gmail.com>
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

using Soup;
using GUPnP;

internal class Rygel.SamsungTVHacks : ClientHacks {
    private const string AGENT = ".*SEC_HHP.*|.*SEC HHP.*";

    private static Regex mime_regex;
    private static Regex dlna_regex;

    static construct {
        try {
            mime_regex = new Regex ("png");
            dlna_regex = new Regex ("PNG");
        } catch (RegexError error) {
            assert_not_reached ();
        }
    }

    public SamsungTVHacks (ServerMessage? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override void apply (MediaObject object) {
        foreach (var resource in object.get_resource_list ()) {
            if (resource.mime_type == "video/x-matroska") {
                resource.mime_type = "video/x-mkv";
            } else if (resource.mime_type == "video/mp2t") {
                // Required to play Panasonic TZ-7 AVCHD-Lite movies. Verified
                // on D+E-Series TV
                // Example: http://s3.amazonaws.com/movies.dpreview.com/panasonic_dmcfz150/00015.MTS
                resource.mime_type = "video/vnd.dlna.mpeg-tts";
            } else if (resource.mime_type == "video/quicktime") {
                // Required to play Canon EOS camera movies. Verfied on
                // D-Series TV (E-Series still don't work)
                // Example: http://s3.amazonaws.com/movies.dpreview.com/canon_eos60d/MVI_1326.MOV
                resource.mime_type = "video/mp4";
            }
        }

        var item = object as VisualItem;
        if (item == null) {
            return;
        }

        // Samsung TVs only accept thumbnails with DLNA profile and mime
        // type JPEG. This is correct from a DLNA pov, but we usually only
        // supply PNG. When fooled into accepting it, they're rendered fine,
        // however.
        // TODO: Unifiy with Panasonic hack!
        foreach (var thumbnail in item.thumbnails) {
            try {
                thumbnail.mime_type = mime_regex.replace_literal
                                        (thumbnail.mime_type, -1, 0, "jpeg");
                thumbnail.dlna_profile = dlna_regex.replace_literal
                                        (thumbnail.dlna_profile, -1, 0, "JPEG");
            } catch (RegexError error) {
                assert_not_reached ();
            }
        }
    }

    public override bool force_seek () {
        return true;
    }

    public override void modify_headers (HTTPRequest request) {
        var item = request.object as VideoItem;

        if (request.msg.get_request_headers ().get_one ("getCaptionInfo.sec") != null
            && item != null
            && item.subtitles.size > 0) {
                var caption_uri = request.http_server.create_uri_for_object
                                        (item,
                                         -1,
                                         0, // FIXME: offer first subtitle only?
                                         null);

                request.msg.get_response_headers().append ("CaptionInfo.sec",
                                                           caption_uri);
        }
    }
}
