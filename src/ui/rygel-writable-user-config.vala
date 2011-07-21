/*
 * Copyright (C) 2008-2011 Nokia Corporation.
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

/**
 * Manages the user configuration for Rygel.
 */
public class Rygel.WritableUserConfig : Rygel.UserConfig {
    private const string RYGEL_SERVICE = "org.gnome.Rygel1";
    private const string RYGEL_PATH = "/org/gnome/Rygel1";
    private const string RYGEL_INTERFACE = "org.gnome.Rygel1";

    public WritableUserConfig () throws Error {
        var path = Path.build_filename (Environment.get_user_config_dir (),
                                        CONFIG_FILE);

        base (path);
    }

    public void set_upnp_enabled (bool value) {
        bool enabled = false;

        try {
            enabled = this.get_upnp_enabled ();
        } catch (GLib.Error err) {}

        if (value != enabled) {
            this.enable_upnp (value);
        }
    }

    public void set_interface (string? value) {
        string iface;

        if (value != null) {
            iface = value;
        } else {
            iface = "";
        }

        this.set_string ("general", IFACE_KEY, iface);
    }

    public void set_port (int value) {
        this.set_int ("general", PORT_KEY, value);
    }

    public void set_transcoding (bool value) {
        this.set_bool ("general", TRANSCODING_KEY, value);
    }

    public void set_mp3_transcoder (bool value) {
        this.set_bool ("general", MP3_TRANSCODER_KEY, value);
    }

    public void set_mp2ts_transcoder (bool value) {
        this.set_bool ("general", MP2TS_TRANSCODER_KEY, value);
    }

    public void set_lpcm_transcoder (bool value) {
        this.set_bool ("general", LPCM_TRANSCODER_KEY, value);
    }

    public void set_wmv_transcoder (bool value) {
        this.set_bool ("general", WMV_TRANSCODER_KEY, value);
    }

    public void set_allow_upload (bool value) throws GLib.Error {
        this.set_bool ("general", ALLOW_UPLOAD_KEY, value);
    }

    public void set_allow_deletion (bool value) throws GLib.Error {
        this.set_bool ("general", ALLOW_DELETION_KEY, value);
    }

    public void save () {
        // Always write to user's config
        string path = Path.build_filename (Environment.get_user_config_dir (),
                                           CONFIG_FILE);

        size_t length;
        var data = this.key_file.to_data (out length);

        try {
            FileUtils.set_contents (path, data, (long) length);
        } catch (FileError err) {
            critical (_("Failed to save configuration data to file '%s': %s"),
                      path,
                      err.message);
        }
    }

    public void set_string (string section,
                            string key,
                            string value) {
        this.key_file.set_string (section, key, value);
    }

    public void set_string_list (string                section,
                                 string                key,
                                 Gee.ArrayList<string> str_list) {
        // GConf requires us to provide it GLib.SList
        var strings = new string[str_list.size];
        int i = 0;

        foreach (var str in str_list) {
            if (str != "") {
                strings[i++] = str;
            }
        }

        this.key_file.set_string_list (section, key, strings);
    }

    public void set_int (string section,
                         string key,
                         int    value) {
        this.key_file.set_integer (section, key, value);
    }

    public void set_bool (string section,
                          string key,
                          bool   value) {
        this.key_file.set_boolean (section, key, value);
    }

    private void enable_upnp (bool enable) {
        try {
            var config_dir = Environment.get_user_config_dir ();
            this.ensure_dir_exists (config_dir);
            var dest_dir = Path.build_filename (config_dir, "autostart");
            this.ensure_dir_exists (dest_dir);

            var dest_path = Path.build_filename (dest_dir, "rygel.desktop");
            var dest = File.new_for_path (dest_path);

            if (enable) {
                // TODO: Use null in watch_name once vala situation in jhbuild
                // is cleared and vala dependency is bumped.
                BusNameAppearedCallback a = null;
                BusNameVanishedCallback b = null;

                // Creating the proxy starts the service
                Bus.watch_name (BusType.SESSION,
                                DBusInterface.SERVICE_NAME,
                                BusNameWatcherFlags.AUTO_START,
                                (owned) a,
                                (owned) b);

                // Then symlink the desktop file to user's autostart dir
                var source_path = Path.build_filename (BuildConfig.DESKTOP_DIR,
                                                       "rygel.desktop");
                try {
                    dest.make_symbolic_link (source_path, null);
                } catch (IOError.EXISTS err) {}

                this.set_bool ("general", UPNP_ENABLED_KEY, true);
            } else {
                // Stop service only if already running
                if (this.get_upnp_enabled ()) {
                    // Create proxy to Rygel
                    DBusInterface rygel_proxy = Bus.get_proxy_sync
                                        (BusType.SESSION,
                                         DBusInterface.SERVICE_NAME,
                                         DBusInterface.OBJECT_PATH,
                                         DBusProxyFlags.DO_NOT_LOAD_PROPERTIES);

                    rygel_proxy.shutdown ();
                }

                // Then delete the symlink from user's autostart dir
                try {
                    dest.delete (null);
                } catch (IOError.NOT_FOUND err) {}

                this.set_bool ("general", UPNP_ENABLED_KEY, false);
            }
        } catch (GLib.Error err) {
            string message;

            if (enable) {
                message = _("Failed to start Rygel service: %s");
            } else {
                message = _("Failed to stop Rygel service: %s");
            }

            warning (message, err.message);
        }
    }

    private void ensure_dir_exists (string dir_path) throws GLib.Error {
        var dir = File.new_for_path (dir_path);

        try {
            dir.make_directory (null);
        } catch (IOError.EXISTS err) { /* Thats OK */ }
    }
}

