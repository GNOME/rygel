/*
 * Copyright (C) 2014 Jens Georg
 *
 * Authors: Jens Georg <mail@jensge.org>
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

internal class Rygel.LGTVHacks : ClientHacks {
    private const string AGENT = ".*LGE_DLNA_SDK.*";

    public LGTVHacks (Message? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override void apply (MediaObject object) {
        if (!(object is MediaFileItem)) {
            return;
        }

        var item = object as MediaFileItem;
        if (item.mime_type == "audio/x-vorbis+ogg" ||
            item.mime_type == "audio/x-flac+ogg") {
            item.mime_type = "application/ogg";
        }
    }
}
