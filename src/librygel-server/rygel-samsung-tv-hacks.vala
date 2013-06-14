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
    }

    public override bool force_seek () {
        return true;
    }
}
