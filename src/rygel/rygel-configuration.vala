/*
 * Copyright (C) 2008,2009 Nokia Corporation, all rights reserved.
 * Copyright (C) 2008,2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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

using GConf;
using CStuff;

public errordomain Rygel.ConfigurationError {
    NO_VALUE_SET,
    VALUE_OUT_OF_RANGE
}

/**
 * Interface for dealing with Rygel configuration.
 */
public interface Rygel.Configuration : GLib.Object {
    public abstract bool upnp_enabled { get; set; }

    public abstract string host_ip { get; set; }

    public abstract int port { get; set; }

    public abstract bool transcoding { get; set; }

    public abstract bool mp3_transcoder { get; set; }

    public abstract bool mp2ts_transcoder { get; set; }

    public abstract bool lpcm_transcoder { get; set; }

    public abstract bool get_enabled (string section);

    public abstract string get_title (string section, string default_title);

    public abstract string get_string (string section,
                                       string key) throws GLib.Error;

    public abstract Gee.ArrayList<string> get_string_list (
                                                    string section,
                                                    string key)
                                                    throws GLib.Error;

    public abstract int get_int (string section,
                                 string key,
                                 int    min,
                                 int    max)
                                 throws GLib.Error;

    public abstract Gee.ArrayList<int> get_int_list (string section,
                                                     string key)
                                                     throws GLib.Error;

    public abstract bool get_bool (string section,
                                   string key)
                                   throws GLib.Error;
}

