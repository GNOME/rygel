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

using Soup;
using Gee;

internal abstract class Rygel.Mediathek.PlaylistParser : Object {
    public Session session { get; construct; }
    public string playlist_suffix { get; construct; }
    public string mime_type { get; construct; }

    public async Gee.List<string>? parse (string uri) throws VideoItemError {
        var message = new Soup.Message ("GET", uri);

        // FIXME: Revert to SoupUtils once bgo#639702 is fixed
        SourceFunc callback = parse.callback;
        this.session.queue_message (message, () => { callback (); });
        yield;

        if (message.status_code != 200) {
            throw new VideoItemError.NETWORK_ERROR
                                        ("Playlist download failed: %u (%s)",
                                         message.status_code,
                                         Status.get_phrase
                                                      (message.status_code));
        }

        return this.parse_playlist ((string) message.response_body.data,
                                    (int) message.response_body.length);
    }


    public abstract Gee.List<string>? parse_playlist (string data,
                                                      int    length)
                                                      throws VideoItemError;
}
