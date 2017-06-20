/*
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2014 Atlantic PuffinPack AB.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

using GUPnP;

/**
 * This class keeps track of global states that are not dependant on the
 * RygelMediaPlayer.
 *
 * These states are:
 * # URI
 * # MetaData
 * # Number of tracks
 * # Current track
 * # Playback state
 *
 * In case of playlists this class will also control the player. It needs to
 * proxy the playback state to react on end of item to be able to switch to
 * the next item.
 */
public interface Rygel.PlayerController : GLib.Object {

    /* public properties */

    /* this._playback_state mirrors player.playback_state without including
     * non-UPnP "EOS" value. It is updated from notify_state_cb */
    public abstract string playback_state { get; set; }

    public abstract uint n_tracks { get; protected set; }

    public abstract uint track { get; set; }

    public abstract string uri { owned get; protected set; }
    public abstract string metadata { owned get; protected set; }

    public abstract string track_uri { owned get; protected set; }

    public abstract string track_metadata { owned get; protected set; }

    public abstract string next_uri { owned get; protected set; }
    public abstract string next_metadata { owned get; protected set; }

    public abstract string current_transport_actions { owned get; }

    public abstract string play_mode { get; set; }

    /// Return true if the current controller can go into PAUSE playback state
    public abstract bool can_pause { get; }

    public abstract bool next ();

    public abstract bool previous ();

    public abstract void set_single_play_uri (string uri,
                                              string metadata,
                                              string? mime,
                                              string? features);

    public abstract void set_playlist_uri (string uri,
                                           string metadata,
                                           MediaCollection collection);

    public abstract void set_next_single_play_uri (string uri,
                                                   string metadata,
                                                   string? mime,
                                                   string? features);

    public abstract void set_next_playlist_uri (string uri,
                                                string metadata,
                                                MediaCollection collection);

    public abstract bool is_play_mode_valid (string play_mode);

    protected string unescape (string input) {
        var result = input.replace ("&quot;", "\"");
        result = result.replace ("&lt;", "<");
        result = result.replace ("&gt;", ">");
        result = result.replace ("&apos;", "'");
        result = result.replace ("&amp;", "&");

        return result;
    }
}
