/*
 * Copyright (C) 2008,2009 Nokia Corporation.
 * Copyright (C) 2008,2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Krzesimir Nowak <krnowak@openismus.com>
 *         Jens Georg <jensg@openismus.com>
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

public errordomain Rygel.ConfigurationError {
    NO_VALUE_SET,
    VALUE_OUT_OF_RANGE
}

public enum Rygel.ConfigurationEntry {
    INTERFACE,
    PORT,
    TRANSCODING,
    ALLOW_UPLOAD,
    ALLOW_DELETION,
    LOG_LEVELS,
    PLUGIN_PATH,
    VIDEO_UPLOAD_FOLDER,
    MUSIC_UPLOAD_FOLDER,
    PICTURE_UPLOAD_FOLDER
}

public enum Rygel.SectionEntry {
    TITLE,
    ENABLED
}

/**
 * Interface for dealing with Rygel configuration.
 */
public interface Rygel.Configuration : GLib.Object {
    /**
     * Emitted when any of known configuration settings has
     * changed. RygelConfigurationEntry lists known configuration
     * settings.
     */
    public signal void configuration_changed (ConfigurationEntry entry);

    /**
     * Emitted when any of section settings has
     * changed. RygelSectionEntry lists known section settings.
     */
    public signal void section_changed (string section, SectionEntry entry);

    /**
     * Emitted when some custom setting has changed. That happens when
     * changed setting does fit into neither configuration_changed nor
     * section_changed signal.
     */
    public signal void setting_changed (string section, string key);

    [Version (deprecated=true, deprecated_since="0.19.2", replacement="get_interfaces")]
    public abstract string get_interface () throws GLib.Error;

    [CCode (array_length=false, array_null_terminated = true)]
    public abstract string[] get_interfaces () throws GLib.Error;

    public abstract int get_port () throws GLib.Error;

    public abstract bool get_transcoding () throws GLib.Error;

    public abstract bool get_allow_upload () throws GLib.Error;

    public abstract bool get_allow_deletion () throws GLib.Error;

    public abstract string get_log_levels () throws GLib.Error;

    public abstract string get_plugin_path () throws GLib.Error;

    public abstract string get_engine_path () throws GLib.Error;

    public abstract string get_media_engine () throws GLib.Error;

    public abstract string? get_video_upload_folder () throws GLib.Error;

    public abstract string? get_music_upload_folder () throws GLib.Error;

    public abstract string? get_picture_upload_folder () throws GLib.Error;

    public abstract bool get_enabled (string section) throws GLib.Error;

    public abstract string get_title (string section) throws GLib.Error;

    public abstract string get_string (string section,
                                       string key) throws GLib.Error;

    public abstract Gee.ArrayList<string> get_string_list (string section,
                                                           string key)
                                                           throws GLib.Error;

    public Gee.ArrayList<string> get_string_list_with_default (string section,
                                                           string key,
                                                           Gee.ArrayList<string> default) {
        try {
            var result = get_string_list(section, key);
            if (result == null || result.size == 0) {
                return default;
            }

            return result;
        } catch (GLib.Error e) {
            return default;
        }                  
    }  
 
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
