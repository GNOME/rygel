/*
 * Copyright (C) 2011 Red Hat, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

internal class Rygel.PanasonicHacks : ClientHacks {
    private const string AGENT = ".*Panasonic MIL DLNA CP.*";

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

    public PanasonicHacks (Message? message = null) throws ClientHacksError {
        base (AGENT, message);
    }

    public override void apply (MediaObject object) {
        if (!(object is MediaFileItem)) {
            return;
        }

        var item = object as MediaFileItem;

        if (!(item is VisualItem)) {
            return;
        }

        foreach (var thumbnail in (item as VisualItem).thumbnails) {
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
}
