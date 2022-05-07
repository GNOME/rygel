/*
 * Copyright (C) 2014 Jens Georg
 *
 * Authors: Jens Georg <mail@jensge.org>
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

internal class Rygel.LGTVHacks : ClientHacks {
    private const string AGENT = ".*LGE_DLNA_SDK.*";

    public LGTVHacks (ServerMessage? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override void apply (MediaObject object) {
        foreach (var resource in object.get_resource_list ()) {
            if (resource.mime_type == "audio/x-vorbis+ogg" ||
                resource.mime_type == "audio/x-flac+ogg") {
                resource.mime_type = "application/ogg";
            } else if (resource.mime_type == "video/x-matroska") {
                resource.dlna_profile = null;
            } else if (resource.mime_type == "video/x-msvideo") {
                resource.mime_type = "video/avi";
            } else if (resource.mime_type == "video/mp4") {
                resource.dlna_profile = null;
            } else if (resource.mime_type == "application/x-subrip") {
                resource.mime_type = "text/srt";
            }
        }

        if (!(object is MediaFileItem)) {
            return;
        }

        // Re-order resources to it picks up the MP3
        if (object is MusicItem) {
            var resources = object.get_resource_list ();
            var i = 0;

            foreach (var resource in resources) {
                if (resource.dlna_profile != null &&
                    resource.dlna_profile.has_prefix ("MP3")) {
                    break;
                }

                i++;
            }

            if (i > 0 && i < resources.size) {
                var resource = resources.remove_at (i);
                resources.insert (0, resource);
            }
        }

        if (!(object is VideoItem)) {
            return;
        }

        var item = object as VideoItem;
        foreach (var subtitle in item.subtitles) {
            if (subtitle.mime_type == "application/x-subrip") {
                subtitle.mime_type = "text/srt";
            }
        }
    }
}
