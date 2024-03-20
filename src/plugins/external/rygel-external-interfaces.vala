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

[DBus (name = "org.gnome.UPnP.MediaObject2")]
public interface Rygel.External.MediaObjectProxy : DBusProxy {
    public const string IFACE = "org.gnome.UPnP.MediaObject2";
    public const string[] PROPERTIES = { "Parent",
                                                "Type",
                                                "Path",
                                                "DisplayName" };

    public abstract ObjectPath parent { owned get; set; }
    public abstract string display_name { owned get; set; }
    [DBus (name = "Type")]
    public abstract string object_type { owned get; set; }
}

[DBus (name = "org.gnome.UPnP.MediaContainer2")]
public interface Rygel.External.MediaContainerProxy : DBusProxy,
                                                      MediaObjectProxy {
    public const string IFACE = "org.gnome.UPnP.MediaContainer2";
    public const string[] PROPERTIES = { "ChildCount", "Searchable" };

    public signal void updated ();

    public abstract uint child_count { get; set; }
    public abstract uint item_count { get; set; }
    public abstract uint container_count { get; set; }
    public abstract bool searchable { get; set; }

    public abstract async HashTable<string,Variant>[] list_children
                                        (uint     offset,
                                         uint     max_count,
                                         string[] filter)
                                         throws IOError, DBusError;
    public abstract async HashTable<string,Variant>[] list_containers
                                        (uint     offset,
                                         uint     max_count,
                                         string[] filter)
                                         throws IOError, DBusError;
    public abstract async HashTable<string,Variant>[] list_items
                                        (uint     offset,
                                         uint     max_count,
                                         string[] filter)
                                         throws IOError, DBusError;

    // Optional API
    public abstract async HashTable<string,Variant>[] search_objects
                                        (string   query,
                                        uint     offset,
                                        uint     max_count,
                                        string[] filter)
                                        throws IOError, DBusError;

    public abstract ObjectPath icon { owned get; set; }
}

[DBus (name = "org.gnome.UPnP.MediaItem2")]
public interface Rygel.External.MediaItemProxy : DBusProxy, MediaObjectProxy {
    public const string IFACE = "org.gnome.UPnP.MediaItem2";
    public const string[] PROPERTIES = { "URLs",
                                         "MIMEType",
                                         "DLNAProfile",
                                         "Size",
                                         "Artist",
                                         "Album",
                                         "Date",
                                         "Duration",
                                         "Bitrate",
                                         "SampleRate",
                                         "BitsPerSample",
                                         "Width",
                                         "Height",
                                         "ColorDepth",
                                         "PixelWidth",
                                         "PixelHeight",
                                         "Thumbnail",
                                         "AlbumArt",
                                         "TrackNumber" };

    [DBus (name = "URLs")]
    public abstract string[] urls { owned get; set; }
    public abstract string mime_type { owned get; set; }

    // Optional API
    public abstract int size { get; set; }
    public abstract string artist { owned get; set; }
    public abstract string album { owned get; set; }
    public abstract string date { owned get; set; }
    public abstract string genre { owned get; set; }
    public abstract string dlna_profile { owned get; set; }

    // video and audio/music
    // in seconds
    public abstract int duration { get; set; }
    // in bytes/second (braindead, yes but tell that to UPnP authors)
    public abstract int bitrate { get; set; }
    public abstract int sample_rate { get; set; }
    public abstract int bits_per_sample { get; set; }

    // video and images
    public abstract int width { get; set; }
    public abstract int height { get; set; }
    public abstract int color_depth { get; set; }
    public abstract ObjectPath thumbnail { owned get; set; }

    // audio and music
    public abstract ObjectPath album_art { owned get; set; }
}

