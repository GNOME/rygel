/*
 * Copyright (C) 2012 Choe Hwanjin <choe.hwanjin@gmail.com>
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

using Soup;
using GUPnP;

internal class Rygel.SamsungTVHacks : ClientHacks {
    private const string AGENT = ".*SEC_HHP.*|.*SEC HHP.*";

    public SamsungTVHacks (Message? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override void apply (MediaObject object) {
        if (!(object is MediaItem)) {
            return;
        }

        var item = object as MediaItem;
        if (item.mime_type == "video/x-matroska") {
            item.mime_type = "video/x-mkv";
        }
        else if (item.mime_type == "video/mp2t") {
            // Required to play Panasonic TZ-7 AVCHD-Lite movies. Verified on D+E-Series TV
            // Example: http://s3.amazonaws.com/movies.dpreview.com/panasonic_dmcfz150/00015.MTS
            item.mime_type = "video/vnd.dlna.mpeg-tts";
        }
        else if (item.mime_type == "video/quicktime") {
            // Required to play Canon EOS camera movies. Verfied on D-Series TV (E-Series still don't work)
            // Example: http://s3.amazonaws.com/movies.dpreview.com/canon_eos60d/MVI_1326.MOV
            item.mime_type = "video/mp4";
        }
    }

    public override bool force_seek () {
        return true;
    }

    public override void modify_headers (HTTPRequest request) {
        if (request.msg.request_headers.get_one ("getCaptionInfo.sec") != null
            && (request.object is VideoItem)
            && (request.object as VideoItem).subtitles.size > 0) {
                var caption_uri = request.http_server.create_uri_for_item
                                        (request.object as MediaItem,
                                         -1,
                                         0, // FIXME: offer first subtitle only?
                                         null,
                                         null);

                request.msg.response_headers.append ("CaptionInfo.sec",
                                                     caption_uri);
        }
    }
}
