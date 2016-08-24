/*
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Jens Georg <jensg@openismus.com>
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

/**
 * Base class that can be used for configuration implementations.
 *
 * Mainly useful to only implement a small subset of the configuration.
 */
public class Rygel.BaseConfiguration : Rygel.Configuration, Object {
    public virtual string get_interface () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    [CCode (array_length=false, array_null_terminated = true)]
    public virtual string[] get_interfaces () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual int get_port () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual bool get_transcoding () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual bool get_allow_upload () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual bool get_allow_deletion () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string get_log_levels () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string get_plugin_path () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string get_engine_path () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string get_media_engine () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string? get_video_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string? get_music_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string? get_picture_upload_folder () throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual bool get_enabled (string section) throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string get_title (string section) throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual string get_string (string section,
                              string key)
                              throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual int get_int (string section,
                                string key,
                                int    min,
                                int    max)
                                throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual Gee.ArrayList<int> get_int_list (string section,
                                                    string key)
                                                    throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }

    public virtual bool get_bool (string section,
                                  string key)
                                  throws GLib.Error {
        throw new ConfigurationError.NO_VALUE_SET (_("Not implemented"));
    }
}
