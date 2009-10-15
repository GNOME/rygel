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

[DBus (name = "org.freedesktop.Tracker")]
public interface Rygel.TrackerIface : DBus.Object {
    public abstract async int get_version () throws DBus.Error;
}

[DBus (name = "org.freedesktop.Tracker.Keywords")]
public interface Rygel.TrackerKeywordsIface : DBus.Object {
    public abstract async string[,] get_list (string service) throws DBus.Error;
}

[DBus (name = "org.freedesktop.Tracker.Metadata")]
public interface Rygel.TrackerMetadataIface: DBus.Object {
    public abstract async string[,] get_unique_values (string   service,
                                                       string[] meta_types,
                                                       string   query,
                                                       bool     descending,
                                                       int      offset,
                                                       int      max_hits)
                                                       throws DBus.Error;

    public abstract async string[] @get (string   service_type,
                                         string   uri,
                                         string[] keys)
                                         throws DBus.Error;
}

[DBus (name = "org.freedesktop.Tracker.Search")]
public interface Rygel.TrackerSearchIface: DBus.Object {
    public abstract async string[,] query (int live_query_id,
                                           string   service,
                                           string[] fields,
                                           string   search_text,
                                           string[] keywords,
                                           string   query_condition,
                                           bool     sort_by_service,
                                           string[] sort_fields,
                                           bool     sort_descending,
                                           int      offset,
                                           int      max_hits)
                                           throws DBus.Error;
}
