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

using Gee;

private enum Rygel.EntryType {
    STRING,
    BOOL,
    INT
}

/**
 * Manages the user configuration for Rygel.
 */
public class Rygel.UserConfig : GLib.Object, Configuration {
    public const string GENERAL_SECTION = "general";
    public const string CONFIG_FILE = "rygel.conf";
    public const string IFACE_KEY = "interface";
    public const string PORT_KEY = "port";
    public const string ENABLED_KEY = "enabled";
    public const string TITLE_KEY = "title";
    public const string TRANSCODING_KEY = "enable-transcoding";
    public const string ALLOW_UPLOAD_KEY = "allow-upload";
    public const string ALLOW_DELETION_KEY = "allow-deletion";
    public const string LOG_LEVELS_KEY = "log-level";
    public const string PLUGIN_PATH_KEY = "plugin-path";
    public const string ENGINE_PATH_KEY = "engine-path";
    public const string MEDIA_ENGINE_KEY = "media-engine";
    public const string UPLOAD_FOLDER_KEY = "upload-folder";
    public const string VIDEO_UPLOAD_DIR_PATH_KEY =
                                        "video-" + UPLOAD_FOLDER_KEY;
    public const string MUSIC_UPLOAD_DIR_PATH_KEY =
                                        "music-" + UPLOAD_FOLDER_KEY;
    public const string PICTURE_UPLOAD_DIR_PATH_KEY =
                                        "picture-" + UPLOAD_FOLDER_KEY;

    // Our singleton
    private static UserConfig config;

    private uint system_config_timer_id = 0;
    private uint local_config_timer_id = 0;

    private class ConfigPair {
        public ConfigurationEntry entry;
        public EntryType type;

        public ConfigPair (ConfigurationEntry entry,
                           EntryType type) {
            this.entry = entry;
            this.type = type;
        }
    }

    private class SectionPair {
        public SectionEntry entry;
        public EntryType type;

        public SectionPair (SectionEntry entry,
                            EntryType type) {
            this.entry = entry;
            this.type = type;
        }
    }

    private static HashMap<string, HashMap<string, ConfigPair> > config_keys;
    private static HashMap<string, SectionPair> section_keys;

    protected KeyFile key_file;
    protected KeyFile sys_key_file;
    protected FileMonitor key_file_monitor;
    protected FileMonitor sys_key_file_monitor;

    static construct {
        var general_config_keys = new HashMap<string, ConfigPair> ();

        UserConfig.config_keys =
                           new HashMap<string, HashMap<string, ConfigPair> > ();
        UserConfig.section_keys = new HashMap<string, SectionPair> ();

        general_config_keys.set (IFACE_KEY,
                                 new ConfigPair (ConfigurationEntry.INTERFACE,
                                                 EntryType.STRING));
        general_config_keys.set (PORT_KEY,
                                 new ConfigPair (ConfigurationEntry.PORT,
                                                 EntryType.INT));
        general_config_keys.set (TRANSCODING_KEY,
                                 new ConfigPair (ConfigurationEntry.TRANSCODING,
                                                 EntryType.BOOL));
        general_config_keys.set (ALLOW_UPLOAD_KEY,
                                 new ConfigPair
                                        (ConfigurationEntry.ALLOW_UPLOAD,
                                         EntryType.BOOL));
        general_config_keys.set (ALLOW_DELETION_KEY,
                                 new ConfigPair
                                        (ConfigurationEntry.ALLOW_DELETION,
                                         EntryType.BOOL));
        general_config_keys.set (LOG_LEVELS_KEY,
                                 new ConfigPair (ConfigurationEntry.LOG_LEVELS,
                                                 EntryType.STRING));
        general_config_keys.set (PLUGIN_PATH_KEY,
                                 new ConfigPair (ConfigurationEntry.PLUGIN_PATH,
                                                 EntryType.STRING));
        general_config_keys.set (VIDEO_UPLOAD_DIR_PATH_KEY,
                                 new ConfigPair
                                        (ConfigurationEntry.VIDEO_UPLOAD_FOLDER,
                                         EntryType.STRING));
        general_config_keys.set (MUSIC_UPLOAD_DIR_PATH_KEY,
                                 new ConfigPair
                                        (ConfigurationEntry.MUSIC_UPLOAD_FOLDER,
                                         EntryType.STRING));
        general_config_keys.set (PICTURE_UPLOAD_DIR_PATH_KEY,
                                 new ConfigPair
                                      (ConfigurationEntry.PICTURE_UPLOAD_FOLDER,
                                       EntryType.STRING));

        UserConfig.config_keys.set (GENERAL_SECTION, general_config_keys);

        section_keys.set (ENABLED_KEY,
                          new SectionPair (SectionEntry.ENABLED,
                                           EntryType.BOOL));
        section_keys.set (TITLE_KEY,
                          new SectionPair (SectionEntry.TITLE,
                                           EntryType.STRING));
    }

    [CCode (array_length=false, array_null_terminated = true)]
    public string[] get_interfaces () throws GLib.Error {
        var interfaces = this.get_string_list (GENERAL_SECTION,
                                               IFACE_KEY).to_array ();
        // to_array () is not null-terminated
        if (interfaces != null) {
            interfaces += null;
        }

        return interfaces;
    }

    public string get_interface () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, IFACE_KEY);
    }

    public int get_port () throws GLib.Error {
        return this.get_int (GENERAL_SECTION, PORT_KEY, uint16.MIN, uint16.MAX);
    }

    public bool get_transcoding () throws GLib.Error {
        return this.get_bool (GENERAL_SECTION, TRANSCODING_KEY);
    }

    public bool get_allow_upload () throws GLib.Error {
        return this.get_bool (GENERAL_SECTION, ALLOW_UPLOAD_KEY);
    }

    public bool get_allow_deletion () throws GLib.Error {
        return this.get_bool (GENERAL_SECTION, ALLOW_DELETION_KEY);
    }

    public string get_log_levels () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, LOG_LEVELS_KEY);
    }

    public string get_plugin_path () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, PLUGIN_PATH_KEY);
    }

    public string get_engine_path () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, ENGINE_PATH_KEY);
    }

    public string get_media_engine () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, MEDIA_ENGINE_KEY);
    }

    public string? get_video_upload_folder () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, VIDEO_UPLOAD_DIR_PATH_KEY);
    }

    public string? get_music_upload_folder () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, MUSIC_UPLOAD_DIR_PATH_KEY);
    }

    public string? get_picture_upload_folder () throws GLib.Error {
        return this.get_string (GENERAL_SECTION, PICTURE_UPLOAD_DIR_PATH_KEY);
    }

    public static UserConfig get_default () throws Error {
        if (UserConfig.config == null) {
            var path = Path.build_filename (Environment.get_user_config_dir (),
                                            CONFIG_FILE);
            UserConfig.config = new UserConfig (path);
        }

        return UserConfig.config;
    }

    private void initialize (string local_path,
                             string system_path) throws Error {
        this.key_file = new KeyFile ();
        this.sys_key_file = new KeyFile ();

        this.sys_key_file.load_from_file (system_path,
                                          KeyFileFlags.KEEP_COMMENTS |
                                          KeyFileFlags.KEEP_TRANSLATIONS);
        debug ("Loaded system configuration from file '%s'", system_path);

        var sys_key_g_file = File.new_for_path (system_path);
        this.sys_key_file_monitor = sys_key_g_file.monitor_file
                                        (FileMonitorFlags.NONE,
                                         null);

        this.sys_key_file_monitor.changed.connect
                                        (this.on_system_config_changed);

        try {
            this.key_file.load_from_file (local_path,
                                          KeyFileFlags.KEEP_COMMENTS |
                                          KeyFileFlags.KEEP_TRANSLATIONS);

            debug ("Loaded user configuration from file '%s'", local_path);
        } catch (Error error) {
            // TRANSLATORS: First %s is the file's path, second is the error message
            warning (_("Failed to load user configuration from file “%s”: %s"),
                   local_path,
                   error.message);
            this.key_file = new KeyFile ();
        }

        var key_g_file = File.new_for_path (local_path);

        this.key_file_monitor = key_g_file.monitor_file (FileMonitorFlags.NONE,
                                                         null);
        this.key_file_monitor.changed.connect (this.on_local_config_changed);
    }

    public UserConfig (string local_path) throws Error {
        var system_path = Path.build_filename (BuildConfig.SYS_CONFIG_DIR,
                                               CONFIG_FILE);

        this.initialize (local_path, system_path);
    }

    public UserConfig.with_paths (string local_path,
                                  string system_path) throws Error {
        this.initialize (local_path, system_path);
    }

    public bool get_enabled (string section) throws GLib.Error {
        return this.get_bool (section, ENABLED_KEY);
    }

    public string get_title (string section) throws GLib.Error {
        return this.get_string (section, TITLE_KEY);
    }

    private static string get_string_from_keyfiles (string section,
                                                    string key,
                                                    KeyFile key_file,
                                                    KeyFile sys_key_file)
                                                    throws GLib.Error {
        string val;

        try {
            val = key_file.get_string (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = sys_key_file.get_string (section, key);
            } else {
                throw error;
            }
        }

        if (val == null || val == "") {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for “%s”"), key);
        }

        return val;
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        return UserConfig.get_string_from_keyfiles (section,
                                                    key,
                                                    this.key_file,
                                                    this.sys_key_file);
    }

    private static ArrayList<string> get_string_list_from_keyfiles
                                        (string section,
                                         string key,
                                         KeyFile key_file,
                                         KeyFile sys_key_file)
                                         throws GLib.Error {
        var str_list = new ArrayList<string> ();
        string[] strings;

        try {
            strings = key_file.get_string_list (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                strings = sys_key_file.get_string_list (section, key);
            } else {
                throw error;
            }
        }

        foreach (var str in strings) {
            str_list.add (str);
        }

        return str_list;
    }

    public ArrayList<string> get_string_list (string section,
                                              string key) throws GLib.Error {
        return UserConfig.get_string_list_from_keyfiles (section,
                                                         key,
                                                         this.key_file,
                                                         this.sys_key_file);
    }

    private static int get_int_from_keyfiles (string section,
                                              string key,
                                              int    min,
                                              int    max,
                                              KeyFile key_file,
                                              KeyFile sys_key_file)
                                              throws GLib.Error {
        int val;

        try {
            val = key_file.get_integer (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = sys_key_file.get_integer (section, key);
            } else {
                throw error;
            }
        }

        if (val < min || val > max) {
            throw new ConfigurationError.VALUE_OUT_OF_RANGE
                                        (_("Value of “%s” out of range"), key);
        }

        return val;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max) throws GLib.Error {
        return UserConfig.get_int_from_keyfiles (section,
                                                 key,
                                                 min,
                                                 max,
                                                 this.key_file,
                                                 this.sys_key_file);
    }

    private static ArrayList<int> get_int_list_from_keyfiles
                                        (string section,
                                         string key,
                                         KeyFile key_file,
                                         KeyFile sys_key_file)
                                         throws GLib.Error {
        var int_list = new ArrayList<int> ();
        int[] ints;

        try {
            ints = key_file.get_integer_list (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                ints = sys_key_file.get_integer_list (section, key);
            } else {
                throw error;
            }
        }

        foreach (var num in ints) {
            int_list.add (num);
        }

        return int_list;
    }

    public ArrayList<int> get_int_list (string section,
                                        string key) throws GLib.Error {
        return UserConfig.get_int_list_from_keyfiles (section,
                                                      key,
                                                      this.key_file,
                                                      this.sys_key_file);
    }

    private static bool get_bool_from_keyfiles (string section,
                                                string key,
                                                KeyFile key_file,
                                                KeyFile sys_key_file)
                                                throws GLib.Error {
        bool val;

        try {
            val = key_file.get_boolean (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = sys_key_file.get_boolean (section, key);
            } else {
                throw error;
            }
        }

        return val;
    }

    public bool get_bool (string section,
                          string key) throws GLib.Error {
        return UserConfig.get_bool_from_keyfiles (section,
                                                  key,
                                                  key_file,
                                                  sys_key_file);
    }

    private static string get_value_from_keyfiles (string section,
                                                   string key,
                                                   KeyFile key_file,
                                                   KeyFile sys_key_file)
                                                   throws GLib.Error {
        string val;

        try {
            val = key_file.get_value (section, key);
        } catch (KeyFileError error) {
            if (error is KeyFileError.KEY_NOT_FOUND ||
                error is KeyFileError.GROUP_NOT_FOUND) {
                val = sys_key_file.get_value (section, key);
            } else {
                throw error;
            }
        }

        return val;
    }

    private static HashSet<string> get_sections (KeyFile key_file,
                                                 KeyFile sys_key_file) {
        var sections = new HashSet<string> ();

        foreach (var section in key_file.get_groups ()) {
            sections.add (section);
        }

        foreach (var section in sys_key_file.get_groups ()) {
            sections.add (section);
        }

        return sections;
    }

    private static HashSet<string> get_keys (string section,
                                             KeyFile key_file,
                                             KeyFile sys_key_file) {
        var keys = new HashSet<string> ();

        try {
            foreach (var key in key_file.get_keys (section)) {
                keys.add (key);
            }
        } catch (GLib.Error e) {}

        try {
            foreach (var key in sys_key_file.get_keys (section)) {
                keys.add (key);
            }
        } catch (GLib.Error e) {}

        return keys;
    }

    private static bool are_values_different (string section,
                                              string key,
                                              KeyFile old_key_file,
                                              KeyFile old_sys_key_file,
                                              KeyFile new_key_file,
                                              KeyFile new_sys_key_file,
                                              EntryType type) {
        try {
            switch (type) {
            case EntryType.STRING:
                var old_value = UserConfig.get_string_from_keyfiles
                                        (section,
                                         key,
                                         old_key_file,
                                         old_sys_key_file);
                var new_value = UserConfig.get_string_from_keyfiles
                                        (section,
                                         key,
                                         new_key_file,
                                         new_sys_key_file);

                return (old_value != new_value);

            case EntryType.BOOL:
                var old_value = UserConfig.get_bool_from_keyfiles
                                        (section,
                                         key,
                                         old_key_file,
                                         old_sys_key_file);
                var new_value = UserConfig.get_bool_from_keyfiles
                                        (section,
                                         key,
                                         new_key_file,
                                         new_sys_key_file);

                return (old_value != new_value);

            case EntryType.INT:
                var old_value = UserConfig.get_int_from_keyfiles
                                        (section,
                                         key,
                                         int.MIN,
                                         int.MAX,
                                         old_key_file,
                                         old_sys_key_file);
                var new_value = UserConfig.get_int_from_keyfiles
                                        (section,
                                         key,
                                         int.MIN,
                                         int.MAX,
                                         new_key_file,
                                         new_sys_key_file);

                return (old_value != new_value);

            default:
                assert_not_reached ();
            }
        } catch (GLib.Error e) {
            // should not happen, because we check for existence
            // of the keys in both keyfile pairs beforehand.
            return true;
        }
    }

    private void emit_conditionally (string section,
                                     string key,
                                     KeyFile old_key_file,
                                     KeyFile old_sys_key_file,
                                     KeyFile key_file,
                                     KeyFile sys_key_file,
                                     HashMap<string, ConfigPair> config_keys) {
        if (UserConfig.section_keys.has_key (key)) {
            // known section key
            var pair = UserConfig.section_keys.get (key);
            var emit = UserConfig.are_values_different (section,
                                                        key,
                                                        old_key_file,
                                                        old_sys_key_file,
                                                        key_file,
                                                        sys_key_file,
                                                        pair.type);

            if (emit) {
                this.section_changed (section, pair.entry);
            }
        } else if (config_keys.has_key (key)) {
            var pair = config_keys.get (key);
            var emit = UserConfig.are_values_different (section,
                                                        key,
                                                        old_key_file,
                                                        old_sys_key_file,
                                                        key_file,
                                                        sys_key_file,
                                                        pair.type);

            if (emit) {
                this.configuration_changed (pair.entry);
            }
        } else {
            // here we compare raw values - we have no
            // knowledge about type of the setting.
            var emit = false;

            try {
                var old_value = UserConfig.get_value_from_keyfiles
                                        (section,
                                         key,
                                         old_key_file,
                                         old_sys_key_file);
                var new_value = UserConfig.get_value_from_keyfiles
                                        (section,
                                         key,
                                         key_file,
                                         sys_key_file);

                emit = old_value != new_value;
            } catch (GLib.Error e) {
                // should not happen, because we check for existence
                // of the keys in both keyfile pairs beforehand.
                emit = true;
            }

            if (emit) {
                this.setting_changed (section, key);
            }
        }
    }

    private void emit_unconditionally
                                     (string section,
                                      string key,
                                      HashMap<string, ConfigPair> config_keys) {
        if (UserConfig.section_keys.has_key (key)) {
            var pair = UserConfig.section_keys.get (key);

            this.section_changed (section, pair.entry);
        } else if (config_keys.has_key (key)) {
            var pair = config_keys.get (key);

            this.configuration_changed (pair.entry);
        } else {
            this.setting_changed (section, key);
        }
    }

    private void compare_and_notify (KeyFile key_file,
                                     KeyFile sys_key_file) {
        var old_key_file = this.key_file;
        var old_sys_key_file = this.sys_key_file;
        var old_sections = UserConfig.get_sections (old_key_file,
                                                    old_sys_key_file);
        var new_sections = UserConfig.get_sections (key_file, sys_key_file);

        this.key_file = key_file;
        this.sys_key_file = sys_key_file;

        foreach (var section in old_sections) {
            var old_keys = UserConfig.get_keys (section,
                                                old_key_file,
                                                old_sys_key_file);
            var config_keys = (UserConfig.config_keys.has_key (section) ?
                               UserConfig.config_keys.get (section) :
                               new HashMap<string, ConfigPair> ());

            if (new_sections.remove (section)) {
                // section exists in old and new configuration
                var new_keys = UserConfig.get_keys (section,
                                                    key_file,
                                                    sys_key_file);

                foreach (var key in old_keys) {
                    if (new_keys.remove (key)) {
                        // key exists in old and new configuration
                        this.emit_conditionally (section,
                                                 key,
                                                 old_key_file,
                                                 old_sys_key_file,
                                                 key_file,
                                                 sys_key_file,
                                                 config_keys);
                    } else {
                        // key disappeared in new configuration
                        this.emit_unconditionally (section, key, config_keys);
                    }
                }
                foreach (var key in new_keys) {
                    // keys here didn't exist in old and appeared in
                    // new one
                    this.emit_unconditionally (section,
                                               key,
                                               config_keys);
                }
            } else {
                // section disappeared in new configuration
                foreach (var key in old_keys) {
                    this.emit_unconditionally (section, key, config_keys);
                }
            }
        }

        foreach (var section in new_sections) {
            // sections here didn't exist in old configuration and
            // appeared in new one
            var keys = UserConfig.get_keys (section, sys_key_file, key_file);
            var config_keys = (UserConfig.config_keys.has_key (section) ?
                               UserConfig.config_keys.get (section) :
                               new HashMap<string, ConfigPair> ());

            foreach (var key in keys) {
                this.emit_unconditionally (section, key, config_keys);
            }
        }
    }

    private void reload_compare_and_notify_system (File system) {
        var sys_key_file = new KeyFile ();

        try {
            sys_key_file.load_from_file (system.get_path (),
                                         KeyFileFlags.KEEP_COMMENTS |
                                         KeyFileFlags.KEEP_TRANSLATIONS);
        } catch (GLib.Error e) {}

        this.compare_and_notify (this.key_file, sys_key_file);
    }

    private void reload_compare_and_notify_local (File local) {
        var key_file = new KeyFile ();

        try {
            key_file.load_from_file (local.get_path (),
                                     KeyFileFlags.KEEP_COMMENTS |
                                     KeyFileFlags.KEEP_TRANSLATIONS);
        } catch (GLib.Error e) {}

        this.compare_and_notify (key_file, this.sys_key_file);
    }

    private void on_system_config_changed (FileMonitor monitor,
                                           File file,
                                           File? other_file,
                                           FileMonitorEvent event_type) {
        if (this.system_config_timer_id != 0) {
            Source.remove (this.system_config_timer_id);
        }
        this.system_config_timer_id = Timeout.add (500, () => {
            this.system_config_timer_id = 0;
            this.reload_compare_and_notify_system (file);

            return false;
        });
    }

    private void on_local_config_changed (FileMonitor monitor,
                                          File file,
                                          File? other_file,
                                          FileMonitorEvent event_type) {
        if (this.local_config_timer_id != 0) {
            Source.remove (this.local_config_timer_id);
        }

        this.local_config_timer_id = Timeout.add (500, () => {
            this.local_config_timer_id = 0;
            this.reload_compare_and_notify_local (file);

            return false;
        });
    }
}
