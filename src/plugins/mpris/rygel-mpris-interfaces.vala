/*
 * Copyright (C) 2009,2010 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

[DBus (name = "org.mpris.MediaPlayer2")]
public interface Rygel.MPRIS.MediaPlayerProxy : DBusProxy {
    public const string IFACE = "org.mpris.MediaPlayer2";

    public abstract string identity { owned get; }
    public abstract string[] supported_uri_schemes { owned get; }
    public abstract string[] supported_mime_types { owned get; }
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public interface Rygel.MPRIS.MediaPlayer.PlayerProxy : DBusProxy,
                                                       MediaPlayerProxy {
    public const string IFACE = "org.mpris.MediaPlayer2.Player";

    public abstract string playback_status { owned get; }
    public abstract double rate { get; set; }
    public abstract double minimum_rate { get; }
    public abstract double maximum_rate { get; }

    public abstract double volume { get; set; }
    public abstract int64 position { get; }
    public abstract bool can_seek { get; }
    public abstract bool can_control { get; }
    public abstract HashTable<string,Variant> metadata { owned get; }

    public abstract void pause () throws IOError, DBusError;
    public abstract void play_pause () throws IOError, DBusError;
    public abstract void stop () throws IOError, DBusError;
    public abstract void play () throws IOError, DBusError;
    public abstract void seek (int64 offset) throws IOError, DBusError;
    public abstract void open_uri (string uri) throws IOError, DBusError;
}
