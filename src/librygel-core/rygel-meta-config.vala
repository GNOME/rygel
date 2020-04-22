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

/**
 * Manages all the configuration sources for Rygel.
 *
 * Abstracts Rygel and its plugins from Configuration implementations. It keeps
 * all real configuration sources in a list and returns the value provided by
 * the first one. If none of them provides the value, it emits an error.
 */
public class Rygel.MetaConfig : GLib.Object, Configuration {
    // Our singleton
    private static MetaConfig meta_config;

    private static ArrayList<Configuration> configs;

    private void connect_signals (Configuration config) {
        config.configuration_changed.connect (this.on_configuration_changed);
        config.section_changed.connect (this.on_section_changed);
        config.setting_changed.connect (this.on_setting_changed);
    }

    public static MetaConfig get_default () {
        if (MetaConfig.configs == null) {
            MetaConfig.configs = new ArrayList<Configuration> ();
        }

        if (meta_config == null) {
            meta_config = new MetaConfig ();

            foreach (var config in MetaConfig.configs) {
                meta_config.connect_signals (config);
            }
        }

        return meta_config;
    }

    /**
     * Register another configuration provider to the meta configuration
     * First configuration to provide a value wins. If you want to assign
     * priority to configuration providers, they have to be added with descending
     * priority
     */
    public static void register_configuration (Configuration config) {
        if (MetaConfig.configs == null) {
            MetaConfig.configs = new ArrayList<Configuration> ();
        }
        configs.add (config);

        if (meta_config != null) {
            meta_config.connect_signals (config);
        }
    }

    /**
     * Convenoience method for cleaning up the singleton. This
     * Should usually not be used; only if you care for your
     * valgrind report or in tests
     */
    public static void cleanup () {
        MetaConfig.meta_config = null;
        MetaConfig.configs = null;
    }

    public string get_interface () throws GLib.Error {
        string val = null;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_interface ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    [CCode (array_length=false, array_null_terminated = true)]
    public string[] get_interfaces () throws GLib.Error {
        string[] val = null;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_interfaces ();
                unavailable = false;
                break;
            } catch (GLib.Error error) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public int get_port () throws GLib.Error {
        int val = 0;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_port ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public bool get_transcoding () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_transcoding ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public bool get_allow_upload () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_allow_upload ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public bool get_allow_deletion () throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_allow_deletion ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public string get_log_levels () throws GLib.Error {
        string val = null;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_log_levels ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public string get_plugin_path () throws GLib.Error {
        string val = null;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_plugin_path ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public string get_media_engine () throws GLib.Error {
        string val = null;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_media_engine ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public string get_engine_path () throws GLib.Error {
        string val = null;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_engine_path ();
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET (_("No value available"));
        }

        return val;
    }

    public string? get_video_upload_folder () throws GLib.Error {
        unowned string? default = Environment.get_user_special_dir
                                        (UserDirectory.VIDEOS);
        var value = default;

        foreach (var config in MetaConfig.configs) {
            try {
                value = config.get_video_upload_folder ();
            } catch (GLib.Error err) { }
        }

        if (value != null && default != null) {
            return value.replace ("@VIDEOS@", default);
        }

        return null;
    }

    public string? get_music_upload_folder () throws GLib.Error {
        unowned string? default = Environment.get_user_special_dir
                                        (UserDirectory.MUSIC);

        var value = default;

        foreach (var config in MetaConfig.configs) {
            try {
                value = config.get_music_upload_folder ();
            } catch (GLib.Error err) {};
        }

        if (value != null && default != null) {
            return value.replace ("@MUSIC@", default);
        }

        return null;
    }

    public string? get_picture_upload_folder () throws GLib.Error {
        unowned string? default = Environment.get_user_special_dir
                                        (UserDirectory.PICTURES);
        var value = default;

        foreach (var config in MetaConfig.configs) {
            try {
                value = config.get_picture_upload_folder ();
            } catch (GLib.Error err) {};
        }

        if (value != null && default != null) {
            return value.replace ("@PICTURES@", default);
        }

        return null;
    }

    public bool get_enabled (string section) throws GLib.Error {
        bool val = true;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_enabled (section);
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            // translators: "enabled" is part of the config key and must not be translated
            var msg = _("No value set for “%s/enabled”");
            throw new ConfigurationError.NO_VALUE_SET (msg, section);
        }

        return val;
    }

    public string get_title (string section) throws GLib.Error {
        string val = null;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_title (section);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            // translators: "title" is part of the config key and must not be translated
            var msg = _("No value set for “%s/title”");
            throw new ConfigurationError.NO_VALUE_SET (msg, section);
        }

        return val;
    }

    public string get_string (string section,
                              string key) throws GLib.Error {
        string val = null;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_string (section, key);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for “%s/%s”"),
                                         section,
                                         key);
        }

        return val;
    }

    public Gee.ArrayList<string> get_string_list (string section,
                                                  string key)
                                                  throws GLib.Error {
        Gee.ArrayList<string> val = null;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_string_list (section, key);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for “%s/%s”"),
                                         section,
                                         key);
        }

        return val;
    }

    public int get_int (string section,
                        string key,
                        int    min,
                        int    max)
                        throws GLib.Error {
        int val = 0;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_int (section, key, min, max);
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for “%s/%s”"),
                                         section,
                                         key);
        }

        return val;
    }

    public Gee.ArrayList<int> get_int_list (string section,
                                            string key)
                                            throws GLib.Error {
        Gee.ArrayList<int> val = null;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_int_list (section, key);
                break;
            } catch (GLib.Error err) {}
        }

        if (val == null) {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for “%s/%s”"),
                                         section,
                                         key);
        }

        return val;
    }

    public bool get_bool (string section,
                          string key)
                          throws GLib.Error {
        bool val = false;
        bool unavailable = true;

        foreach (var config in MetaConfig.configs) {
            try {
                val = config.get_bool (section, key);
                unavailable = false;
                break;
            } catch (GLib.Error err) {}
        }

        if (unavailable) {
            throw new ConfigurationError.NO_VALUE_SET
                                        (_("No value available for “%s/%s”"),
                                         section,
                                         key);
        }

        return val;
    }

    private bool configuration_value_available (Configuration config,
                                                ConfigurationEntry entry) {
        try {
            switch (entry) {
            case ConfigurationEntry.INTERFACE:
                config.get_interfaces ();
                break;

            case ConfigurationEntry.PORT:
                config.get_port ();
                break;

            case ConfigurationEntry.TRANSCODING:
                config.get_transcoding ();
                break;

            case ConfigurationEntry.ALLOW_UPLOAD:
                config.get_allow_upload ();
                break;

            case ConfigurationEntry.ALLOW_DELETION:
                config.get_allow_deletion ();
                break;

            case ConfigurationEntry.LOG_LEVELS:
                config.get_log_levels ();
                break;

            case ConfigurationEntry.PLUGIN_PATH:
                config.get_plugin_path ();
                break;

            case ConfigurationEntry.VIDEO_UPLOAD_FOLDER:
                config.get_video_upload_folder ();
                break;

            case ConfigurationEntry.MUSIC_UPLOAD_FOLDER:
                config.get_music_upload_folder ();
                break;

            case ConfigurationEntry.PICTURE_UPLOAD_FOLDER:
                config.get_picture_upload_folder ();
                break;

            default:
                assert_not_reached ();
            }
        } catch (GLib.Error e) {
            return false;
        }

        return true;
    }

    private void on_configuration_changed (Configuration affected_config,
                                           ConfigurationEntry entry) {
        foreach (var config in MetaConfig.configs) {
            if (config == affected_config) {
                this.configuration_changed (entry);
            } else {
                if (configuration_value_available (config, entry)) {
                    return;
                }
            }
        }
    }

    private bool setting_value_available (Configuration config,
                                          string section,
                                          SectionEntry entry) {
        try {
            switch (entry) {
            case SectionEntry.TITLE:
                config.get_title (section);
                break;

            case SectionEntry.ENABLED:
                config.get_enabled (section);
                break;

            default:
                assert_not_reached ();
            }
        } catch (GLib.Error e) {
            return false;
        }

        return true;
    }

    private void on_section_changed (Configuration affected_config,
                                     string section,
                                     SectionEntry entry) {
        foreach (var config in MetaConfig.configs) {
            if (config == affected_config) {
                this.section_changed (section, entry);
            } else {
                if (setting_value_available (config, section, entry)) {
                    return;
                }
            }
        }
    }

    private void on_setting_changed (Configuration affected_config,
                                     string section,
                                     string key) {
        // The section and key here is actually a catch-wrestling.
        // We emit the setting changed straight away.
        this.setting_changed (section, key);
    }
}
