/*
 * Copyright (C) 2011 Red Hat, Inc.
 * Copyright (C) 2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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
using Soup;
using GUPnP;

internal errordomain Rygel.ClientHacksError {
    NA
}

internal abstract class Rygel.ClientHacks : GLib.Object {
    private const string CORRECT_OBJECT_ID = "ObjectID";

    private static HashMap<string, string> client_agent_cache;

    public unowned string object_id { get;
                                      protected set;
                                      default = CORRECT_OBJECT_ID; }
    protected Regex agent_regex;

    protected ClientHacks (string agent,
                           ServerMessage? message)
                           throws ClientHacksError {
        try {
            this.agent_regex = new Regex (agent,
                                          RegexCompileFlags.CASELESS |
                                          RegexCompileFlags.RAW,
                                          0);
        } catch (RegexError error) {
            // This means subclasses did not provide a proper regular expression
            assert_not_reached ();
        }

        if (message != null) {
            this.check_headers (message);
        }
    }

    public static ClientHacks create (ServerMessage? message)
                                      throws ClientHacksError {
        try {
            return new PanasonicHacks (message);
        } catch (Error error) { }
        try {
            return new XBMC4XBoxHacks (message);
        } catch (Error error) { }

        try {
            return new XBoxHacks (message);
        } catch (Error error) { }

        try {
            return new WMPHacks (message);
        } catch (Error error) { }

        try {
            return new SamsungTVHacks (message);
        } catch (Error error) { }

        try {
            return new SeekHacks (message);
        } catch (Error error) { }

        try {
            return new LGTVHacks (message);
        } catch (Error error) { }

        try {
            return new PhillipsHacks (message);
        } catch (Error error) { }

        try {
            return new RaumfeldHacks (message);
        } catch (Error error) { } 

        return new XBMCHacks (message);
    }

    public virtual void translate_container_id (MediaQueryAction action,
                                                ref string       container_id) {}

    /**
     * Modify the passed media object.
     *
     * Called before serializing the Object to DIDL-Lite.
     */
    public virtual void apply (MediaObject object) {}

    public virtual void filter_sort_criteria (ref string sort_criteria) {}

    public virtual bool force_seek () { return false; }

    public virtual void modify_headers (HTTPRequest request) {}

    public virtual async MediaObjects? search
                                        (SearchableContainer container,
                                         SearchExpression?   expression,
                                         uint                offset,
                                         uint                max_count,
                                         string              sort_criteria,
                                         Cancellable?        cancellable,
                                         out uint            total_matches)
                                         throws Error {
        return yield container.search (expression,
                                       offset,
                                       max_count,
                                       sort_criteria,
                                       cancellable,
                                       out total_matches);
    }

    private void check_headers (ServerMessage message)
                                          throws ClientHacksError {
        var headers = message.get_request_headers();
        var remote_ip = "127.0.0.1"; //message.get_remote_host ();

        var agent = headers.get_one ("User-Agent");
        if (agent == null && client_agent_cache != null) {
            agent = client_agent_cache.get (remote_ip);
        }

        if (agent != null) {
            if (client_agent_cache == null) {
                client_agent_cache = new HashMap<string, string>();
            }
            client_agent_cache.set (remote_ip, agent);
        }

        if (agent == null || !(this.agent_regex.match (agent))) {
            throw new ClientHacksError.NA (_("Not Applicable"));
        }
    }
}
