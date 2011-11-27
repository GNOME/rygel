/*
 * Copyright (C) 2011 Red Hat, Inc.
 * Copyright (C) 2010 Nokia Corporation.
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

internal errordomain Rygel.ClientHacksError {
    NA
}

internal abstract class Rygel.ClientHacks : GLib.Object {
    private const string CORRECT_OBJECT_ID = "ObjectID";

    public unowned string object_id { get; protected set; }

    protected Regex agent_regex;

    public static ClientHacks create_for_action (ServiceAction action)
                                                 throws ClientHacksError {
        try {
            return new XBoxHacks.for_action (action);
        } catch {}

        try {
            return new PanasonicHacks.for_action (action);
        } catch {}

        return new XBMCHacks.for_action (action);
    }

    public static ClientHacks create_for_headers (MessageHeaders headers)
                                                  throws ClientHacksError {
        try {
            return new XBoxHacks.for_headers (headers);
        } catch {}

        try {
            return new PanasonicHacks.for_headers (headers);
        } catch {};

        return new XBMCHacks.for_headers (headers);
    }

    protected ClientHacks (string agent_pattern, MessageHeaders? headers = null)
                           throws ClientHacksError {
        try {
            this.agent_regex = new Regex (agent_pattern,
                                          RegexCompileFlags.CASELESS,
                                          0);
        } catch (RegexError error) {
            // This means subclasses did not provide a proper regular expression
            assert_not_reached ();
        }

        if (headers != null) {
            this.check_headers (headers);
        }

        this.object_id = CORRECT_OBJECT_ID;
    }

    public bool is_album_art_request (Soup.Message message) {
        unowned string query = message.get_uri ().query;

        if (query == null) {
            return false;
        }

        var params = Soup.Form.decode (query);
        var album_art = params.lookup ("albumArt");

        return (album_art != null) && bool.parse (album_art);
    }

    public virtual void translate_container_id (MediaQueryAction action,
                                                ref string       container_id) {}

    public virtual void apply (MediaItem item) {}

    public virtual void filter_sort_criteria (ref string sort_criteria) {}

    public virtual async MediaObjects? search
                                        (SearchableContainer container,
                                         SearchExpression?   expression,
                                         uint                offset,
                                         uint                max_count,
                                         out uint            total_matches,
                                         Cancellable?        cancellable)
                                         throws Error {
        return yield container.search (expression,
                                       offset,
                                       max_count,
                                       out total_matches,
                                       cancellable);
    }

    private void check_headers (MessageHeaders headers)
                                          throws ClientHacksError {
        var agent = headers.get_one ("User-Agent");
        if (agent == null || !(this.agent_regex.match (agent))) {
            throw new ClientHacksError.NA (_("Not Applicable"));
        }
    }
}
