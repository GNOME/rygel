/*
 * Copyright (C) 2009 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

using DBus;

[DBus (name = "org.freedesktop.Tracker1.Statistics")]
public interface Rygel.TrackerStatsIface : DBus.Object {
    public abstract async string[,] get_statistics () throws DBus.Error;
}

[DBus (name = "org.freedesktop.Tracker1.Resources")]
public interface Rygel.TrackerResourcesIface: DBus.Object {
    public abstract async string[,] sparql_query (string query)
                                                  throws DBus.Error;
    public abstract async void sparql_update (string query) throws DBus.Error;
}

[DBus (name = "org.freedesktop.Tracker1.Resources.Class")]
public interface Rygel.TrackerResourcesClassIface: DBus.Object {
    public abstract signal void subjects_added (string[] subjects);
    public abstract signal void subjects_removed (string[] subjects);
    public abstract signal void subjects_changed (string[] before,
                                                  string[] after);
}

namespace Rygel {
    public const string RESOURCES_CLASS_PATH = "/org/freedesktop/Tracker1/" +
                                               "Resources/Classes/";
    public const string MUSIC_RESOURCES_CLASS_PATH = RESOURCES_CLASS_PATH +
                                                     "nmm/MusicPiece";
    public const string VIDEO_RESOURCES_CLASS_PATH = RESOURCES_CLASS_PATH +
                                                     "nmm/Video";
    public const string PHOTO_RESOURCES_CLASS_PATH = RESOURCES_CLASS_PATH +
                                                     "nfo/Image";
}
