/*
 * Copyright (C) 2008,2009 Nokia Corporation.
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

using FreeDesktop;

/**
 * Manages the user configuration for Rygel.
 */
public class Rygel.UserConfig : GLib.Object, Configuration {
    public static const string CONFIG_FILE = "rygel.conf";
    public static const string IFACE_KEY = "interface";
    public static const string PORT_KEY = "port";
    public static const string ENABLED_KEY = "enabled";
    public static const string UPNP_ENABLED_KEY = "upnp-" + ENABLED_KEY;
    public static const string TITLE_KEY = "title";
    public static const string TRANSCODING_KEY = "enable-transcoding";
    public static const string MP3_TRANSCODER_KEY = "enable-mp3-transcoder";
    public static const string MP2TS_TRANSCODER_KEY = "enable-mp2ts-transcoder";
    public static const string LPCM_TRANSCODER_KEY = "enable-lpcm-transcoder";
    public static const string WMV_TRANSCODER_KEY = "enable-wmv-transcoder";
    public static const string AAC_TRANSCODER_KEY = "enable-aac-transcoder";
    public static const string ALLOW_UPLOAD_KEY = "allow-upload";
    public static const string ALLOW_DELETION_KEY = "allow-deletion";
    public static const string LOG_LEVELS_KEY = "log-level";
    public static const string PLUGIN_PATH_KEY = "plugin-path";
    public static const string UPLOAD_FOLDER_KEY = "upload-folder";
    public static const string VIDEO_UPLOAD_DIR_PATH_KEY =
                                        "video-" + UPLOAD_FOLDER_KEY;
    public static const string MUSIC_UPLOAD_DIR_PATH_KEY =
                                        "music-" + UPLOAD_FOLDER_KEY;
    public static const string PICTURE_UPLOAD_DIR_PATH_KEY =
                                        "picture-" + UPLOAD_FOLDER_KEY;

    // Our singleton
    private static UserConfig config;

    protected KeyFile key_file;
    protected KeyFile sys_key_file;

    public bool get_upnp_enabled () throws GLib.Error {
        return this.get_bool ("general", UPNP_ENABLED_KEY);
    }

    public string get_interface () throws GLib.Error {
        return this.get_string ("general", IFACE_KEY);
    }

    public int get_port () throws GLib.Error {
        return this.get_int ("general", PORT_KEY, uint16.MIN, uint16.MAX);
    }

    public bool get_transcoding () throws GLib.Error {
        return this.get_bool ("general", TRANSCODING_KEY);
    }

    public bool get_mp3_transcoder () throws GLib.Error {
        return this.get_bool ("general", MP3_TRANSCODER_KEY);
    }

    public bool get_mp2ts_transcoder () throws GLib.Error {
        return this.get_bool ("general", MP2TS_TRANSCODER_KEY);
    }

    public bool get_lpcm_transcoder () throws GLib.Error {
        return this.get_bool ("general", LPCM_TRANSCODER_KEY);
    }

    public bool get_wmv_transcoder () throws GLib.Error {
        return this.get_bool ("general", WMV_TRANSCODER_KEY);
    }

    public bool get_aac_transcoder () throws GLib.Error {
        return this.get_bool ("general", AAC_TRANSCODER_KEY);
    }

    public bool get_allow_upload () throws GLib.Error {
        return this.get_bool ("general", ALLOW_UPLOAD_KEY);
    }

    public bool get_allow_deletion () throws GLib.Error {
        return this.get_bool ("general", ALLOW_DELETION_KEY);
    }

    public string get_log_levels () throws GLib.Error {
        return this.get_string ("general", LOG_LEVELS_KEY);
    }

    public string get_plugin_path () throws GLib.Error {
        return this.get_string ("general", PLUGIN_PATH_KEY);
    }

    public string get_video_upload_folder () throws GLib.Error {
        return this.get_string ("general", VIDEO_UPLOAD_DIR_PATH_KEY);
    }

    public string get_music_upload_folder () throws GLib.Error {
        return this.get_string ("general", MUSIC_UPLOAD_DIR_PATH_KEY);
    }

    public string get_picture_upload_folder () throws GLib.Error {
        return this.get_string ("general", PICTURE_UPLOAD_DIR_PATH_KEY);
    }

    public static UserConfig get_default () throws Error {
        if (config == null) {
            var path = Path.build_filename
                                        (Environment.get_user_config_dir (),
                                         CONFIG_FILE);
            config = new UserConfig (path);
        }

        return config;
    }

    public UserConfig (string file) throws Error {
        this.key_file = new KeyFile ();
        this.sys_key_file = new KeyFile ();

        var path = Path.build_filename (BuildConfig.SYS_CONFIG_DIR,
                                        CONFIG_FILE);

        this.sys_key_file.load_from_file (path,
                                          KeyFileFlags.KEEP_COMMENTS |
                                          KeyFileFlags.KEEP_TRANSLATIONS);
        debug ("Loaded system configuration from file '%s'", path);

        try {
            this.key_file.load_from_file (file,
                                          KeyFileFlags.KEEP_COMMENTS |
                                          KeyFileFlags.KEEP_TRANSLATIONS);

            debug ("Loaded user configuration from file '%s'", file);
        } catch (Error error) {
            debug ("Failed to load user configuration from file '%s': %s",
                   file,
                   error.message);
            size_t size;

            var data = this.sys_key_file.to_data (out size);
            this.key_file.load_from_data (data,
                                          size,
                                          KeyFileFlags.KEEP_COMMENTS |
                                          KeyFileFlags.KEEP_TRANSLATIONS);
        }
    }

    public bool get_enabled (string section) throws GLib.Error {
        return this.get_bool (section, ENABLED_KEY);
    }

    public string get_title (string section) throws GLib.Error {
        return this.get_string (section, TITLE_KEY);
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        string val;

        try {
            val = this.key_file.get_string (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = this.sys_key_file.get_string (section, key);
            } else {
                throw error;
            }
        }

        if (val == null || val == "") {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for '%s'"), key);
        }

        return val;
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        var str_list = new Gee.ArrayList<string> ();
        string[] strings;

        try {
            strings = this.key_file.get_string_list (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                strings = this.sys_key_file.get_string_list (section, key);
            } else {
                throw error;
            }
        }

        foreach (var str in strings) {
            str_list.add (str);
        }

        return str_list;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int val;

        try {
            val = this.key_file.get_integer (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = this.sys_key_file.get_integer (section, key);
            } else {
                throw error;
            }
        }

        if (val == 0 || val < min || val > max) {
            throw new ConfigurationError.VALUE_OUT_OF_RANGE
                                        (_("Value of '%s' out of range"), key);
        }

        return val;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        var int_list = new Gee.ArrayList<int> ();
        int[] ints;

        try {
            ints = this.key_file.get_integer_list (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                ints = this.sys_key_file.get_integer_list (section, key);
            } else {
                throw error;
            }
        }

        foreach (var num in ints) {
            int_list.add (num);
        }

        return int_list;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        bool val;

        try {
            val = this.key_file.get_boolean (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = this.sys_key_file.get_boolean (section, key);
            } else {
                throw error;
            }
        }

        return val;
    }
}

