/*
 * Copyright (C) 2012 Intel Corporation
 *
 * Author: Krzesimir Nowak <krnowak@openismus.com>
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

public class Rygel.UserConfigTest : GLib.Object {

    // pitiful Vala with no typedefs...
    public class ConfigSet : GLib.Object {
        public HashSet<ConfigurationEntry> gee;

        public ConfigSet () {
            this.gee = new HashSet<ConfigurationEntry> ();
        }
    }

    public class SectionMap : GLib.Object {
        public HashMap<string, HashSet<SectionEntry> > gee;

        public SectionMap () {
            this.gee = new HashMap<string, HashSet<SectionEntry> > ();
        }

        public HashSet<SectionEntry> new_values (string section) {
            var values = new HashSet<SectionEntry> ();

            this.gee.set (section, values);

            return values;
        }
    }

    public class SettingMap : GLib.Object {
        public HashMap<string, HashSet<string> > gee;

        public SettingMap () {
            this.gee = new HashMap<string, HashSet<string> > ();
        }

        public HashSet<string> new_values (string section) {
            var values = new HashSet<string> ();

            this.gee.set (section, values);

            return values;
        }
    }

    private class Settings : GLib.Object {
        public string? general_title;
        public bool? general_enabled;
        public string? general_iface;
        public int? general_port;
        public string? foo_title;
        public bool? foo_enabled;
        public bool? foo_setting;

        private void initialize (string? general_title = null,
                                 bool? general_enabled = null,
                                 string? general_iface = null,
                                 int? general_port = null,
                                 string? foo_title = null,
                                 bool? foo_enabled = null,
                                 bool? foo_setting = null) {
            this.general_title = general_title;
            this.general_enabled = general_enabled;
            this.general_iface = general_iface;
            this.general_port = general_port;
            this.foo_title = foo_title;
            this.foo_enabled = foo_enabled;
            this.foo_setting = foo_setting;
        }

        public Settings (string? general_title = null,
                         bool? general_enabled = null,
                         string? general_iface = null,
                         int? general_port = null,
                         string? foo_title = null,
                         bool? foo_enabled = null,
                         bool? foo_setting = null) {
            this.initialize (general_title,
                             general_enabled,
                             general_iface,
                             general_port,
                             foo_title,
                             foo_enabled,
                             foo_setting);
        }

        public Settings.default () {
            this.initialize ("General",
                             true,
                             "eth0",
                             42,
                             "Foo",
                             true,
                             true);
        }
    }

    private abstract class SettingsAction : GLib.Object {
        protected UserConfigTest test;

        SettingsAction (UserConfigTest test) {
            this.test = test;
        }
        public abstract void perform (string config);
    }

    private class SettingsDoNothing : SettingsAction {
        public SettingsDoNothing (UserConfigTest test) {
            base (test);
        }

        public override void perform (string config) {}
    }

    private class SettingsReplace : SettingsAction {
        private Settings settings;

        public SettingsReplace (UserConfigTest test,
                                Settings settings) {
            base (test);
            this.settings = settings;
        }

        public override void perform (string config) {
            try {
                this.test.set_config (config,
                                  this.settings);
            } catch (GLib.Error error) {
                assert_not_reached ();
            }
        }
    }

    private class SettingsRemove : SettingsAction {
        public SettingsRemove (UserConfigTest test) {
            base (test);
        }

        public override void perform (string config) {
            this.test.remove_config (config);
        }
    }

    private class WatchData : GLib.Object {
        public string description;
        public SettingsAction local_action;
        public SettingsAction system_action;
        public ConfigSet expected_config_changes;
        public SectionMap expected_section_changes;
        public SettingMap expected_setting_changes;

        private bool description_printed;

        private void initialize (string description,
                                 SettingsAction local_action,
                                 SettingsAction system_action,
                                 ConfigSet expected_config_changes,
                                 SectionMap expected_section_changes,
                                 SettingMap expected_setting_changes) {
            this.description = description;
            this.local_action = local_action;
            this.system_action = system_action;
            this.expected_config_changes = expected_config_changes;
            this.expected_section_changes = expected_section_changes;
            this.expected_setting_changes = expected_setting_changes;
            this.description_printed = false;
        }

        public WatchData (string description,
                          SettingsAction local_action,
                          SettingsAction system_action,
                          ConfigSet expected_config_changes,
                          SectionMap expected_section_changes,
                          SettingMap expected_setting_changes) {
            this.initialize (description,
                             local_action,
                             system_action,
                             expected_config_changes,
                             expected_section_changes,
                             expected_setting_changes);
        }

        public WatchData.no_changes (string description,
                                     SettingsAction local_action,
                                     SettingsAction system_action) {
            this.initialize (description,
                             local_action,
                             system_action,
                             new ConfigSet (),
                             new SectionMap (),
                             new SettingMap ());
        }

        public bool empty () {
            return (this.expected_config_changes.gee.size == 0 &&
                    this.expected_section_changes.gee.size == 0 &&
                    this.expected_setting_changes.gee.size == 0);
        }

        public void prepare_setup () {
            this.local_action.perform (LOCAL_CONFIG);
            this.system_action.perform (SYSTEM_CONFIG);
        }

        public void print_description () {
            if (!this.description_printed) {
                this.description_printed = true;
                warning ("Test case: %s.", this.description);
            }
        }

        public void print_expectations () {
            warning ("Expected configuration changes so far:");
            if (this.expected_config_changes.gee.size == 0) {
                warning ("(none)");
            } else {
                foreach (var entry in this.expected_config_changes.gee) {
                    warning ("  %s", entry.to_string ());
                }
            }
            warning ("Expected section changes so far:");
            if (this.expected_section_changes.gee.size == 0) {
                warning ("(none)");
            } else {
                var changes = this.expected_section_changes.gee;

                foreach (var section in changes.keys) {
                    var entries = changes.get (section);

                    warning ("  %s", section);
                    foreach (var entry in entries) {
                        warning ("    %s", entry.to_string ());
                    }
                }
            }
            warning ("Expected setting changes so far:");
            if (this.expected_setting_changes.gee.size == 0) {
                warning ("(none)");
            } else {
                var changes = this.expected_setting_changes.gee;

                foreach (var section in changes.keys) {
                    var keys = changes.get (section);

                    warning ("  %s", section);
                    foreach (var key in keys) {
                        warning ("    %s", key);
                    }
                }
            }
        }
    }

    private static string LOCAL_CONFIG = "user-config-test-local.ini";
    private static string SYSTEM_CONFIG = "user-config-test-system.ini";
    private static string GENERAL = "general";
    private static string FOO = "foo";

    private MainLoop main_loop;
    private UserConfig config;
    private bool fail;
    private WatchData current_watch_data;
    private uint timeout_id;
    private HashMap<string, Settings> last_settings;

    private void set_config (string path,
                             Settings settings = new Settings ()) throws Error {
        KeyFile key_file = new KeyFile ();

        this.last_settings.set (path, settings);

        if (settings.general_title != null) {
            key_file.set_string (GENERAL, "title", settings.general_title);
        }
        if (settings.general_enabled != null) {
            key_file.set_boolean (GENERAL, "enabled", settings.general_enabled);
        }
        if (settings.general_iface != null) {
            key_file.set_string (GENERAL, "interface", settings.general_iface);
        }
        if (settings.general_port != null) {
            key_file.set_integer (GENERAL, "port", settings.general_port);
        }

        if (settings.foo_title != null) {
            key_file.set_string (FOO, "title", settings.foo_title);
        }
        if (settings.foo_enabled != null) {
            key_file.set_boolean (FOO, "enabled", settings.foo_enabled);
        }
        if (settings.foo_setting != null) {
            key_file.set_boolean (FOO, "setting", settings.foo_setting);
        }

        var tmp_path = path + ".tmp";
        size_t size;
        var data = key_file.to_data (out size);

        FileUtils.set_contents (tmp_path, data, (ssize_t)size);
        FileUtils.rename (tmp_path, path);
    }

    private void remove_config (string path) {
        FileUtils.unlink (path);
        this.last_settings.set (path, new Settings ());
    }

    public UserConfigTest () {
        this.main_loop = new MainLoop (null, false);
        this.fail = false;
        this.timeout_id = 0;
        this.last_settings = new HashMap<string, Settings> ();

        this.last_settings.set (LOCAL_CONFIG, new Settings ());
        this.last_settings.set (SYSTEM_CONFIG, new Settings ());
    }

    private void try_load (bool expect_failure) {
        var failed = false;

        try {
            var config = new UserConfig.with_paths (LOCAL_CONFIG,
                                                    SYSTEM_CONFIG);
            assert (config != null);
        } catch (Error e) {
            failed = true;
        }
        if (expect_failure != failed) {
            warning ("Unexpected %s of UserConfig creation.",
                     (expect_failure ? "success" : "failure"));
            this.fail = true;
        }
    }

    private class ConfigRemover {
        private UserConfigTest test;

        public ConfigRemover (UserConfigTest test) {
            this.test = test;
        }

        ~ConfigRemover () {
            this.test.remove_config (LOCAL_CONFIG);
            this.test.remove_config (SYSTEM_CONFIG);
        }
    }

    private void test_loading () {
        var remover = new ConfigRemover (this);
        assert (remover != null);

	try {
            this.set_config (LOCAL_CONFIG);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        try {
            this.set_config (SYSTEM_CONFIG);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }
        this.try_load (false);
        this.remove_config (LOCAL_CONFIG);
        this.try_load (false);
        this.remove_config (SYSTEM_CONFIG);
        this.try_load (true);
        // Should not fail when system config does not exist but local
        // do.
        // https://bugzilla.gnome.org/show_bug.cgi?id=683959

        // this.set_config (LOCAL_CONFIG);
        // this.try_load (false);
    }

    private void data_check () {
        if (this.current_watch_data.empty ()) {
            if (this.timeout_id != 0) {
                Source.remove (this.timeout_id);
                this.timeout_id = 0;
            }
            this.main_loop.quit ();
        }
    }

    private void on_configuration_changed (Configuration config,
                                           ConfigurationEntry entry) {
        var changes = this.current_watch_data.expected_config_changes.gee;

        if (changes.remove (entry)) {
            this.data_check ();
        } else {
            this.current_watch_data.print_description ();
            warning ("Unexpected change of configuration entry: %s",
                     entry.to_string ());
            this.fail = true;
        }
    }

    private void on_section_changed (Configuration config,
                                     string section,
                                     SectionEntry entry) {
        var changes = this.current_watch_data.expected_section_changes.gee;

        if (changes.has_key (section)) {
            var entries = changes.get (section);

            if (entries.remove (entry)) {
                if (entries.size == 0) {
                    changes.unset (section);
                }
                this.data_check ();
            } else {
                this.current_watch_data.print_description ();
                warning ("Unexpected change in expected section: %s, " +
                         "unexpected entry: %s.",
                         section,
                         entry.to_string ());
                this.fail = true;
            }
        } else {
            this.current_watch_data.print_description ();
            warning ("Unexpected change in unexpected section: %s, entry %s.",
                     section,
                     entry.to_string ());
            this.fail = true;
        }
    }

    private void on_setting_changed (Configuration config,
                                     string section,
                                     string key) {
        var changes = this.current_watch_data.expected_setting_changes.gee;

        if (changes.has_key (section)) {
            var keys = changes.get (section);

            if (keys.remove (key)) {
                if (keys.size == 0) {
                    changes.unset (section);
                }
                this.data_check ();
            } else {
                this.current_watch_data.print_description ();
                warning ("Unexpected change in expected setting section: %s, " +
                         "unexpected setting key: %s.",
                         section,
                         key);
                this.fail = true;
            }
        } else {
            this.current_watch_data.print_description ();
            warning ("Unexpected change in unexpected setting section: %s, " +
                     "setting key: %s",
                     section,
                     key);
            this.fail = true;
        }
    }

    private ArrayList<WatchData> prepare_watch_data () {
        var data = new ArrayList<WatchData> ();
        var do_nothing = new SettingsDoNothing (this);


        // change nothing, expect no changes.
        {
            var desc = "change nothing, expect no changes";

            data.add (new WatchData.no_changes (desc, do_nothing, do_nothing));
        }

        // set new config but with the same contents as before, expect
        // no changes.
        {
            var desc = "set new config but with the same contents as before, " +
                "expect no changes";
            var last_local = new SettingsReplace
                                        (this,
                                         this.last_settings.get (LOCAL_CONFIG));
            var last_system = new SettingsReplace
                                       (this,
                                        this.last_settings.get (SYSTEM_CONFIG));

            data.add (new WatchData.no_changes (desc, last_local, last_system));
        }

        // set empty system config, expect no changes
        {
            var desc = "set empty system config, expect no changes";
            var empty = new SettingsReplace (this, new Settings ());

            data.add (new WatchData.no_changes (desc, do_nothing, empty));
        }

        // change all possible values in local config, expect lots of
        // changes
        {
            var desc = "change all possible values in local config, expect " +
                "lots of changes";
            var config = new ConfigSet ();

            config.gee.add (ConfigurationEntry.INTERFACE);
            config.gee.add (ConfigurationEntry.PORT);

            var section = new SectionMap ();
            var general_section = section.new_values (GENERAL);
            var foo_section = section.new_values (FOO);

            general_section.add (SectionEntry.TITLE);
            general_section.add (SectionEntry.ENABLED);
            foo_section.add (SectionEntry.TITLE);
            foo_section.add (SectionEntry.ENABLED);

            var setting = new SettingMap ();
            var foo_setting = setting.new_values (FOO);

            foo_setting.add ("setting");

            var new_local = new SettingsReplace
                                        (this,
                                         new Settings ("Changed!",
                                                       false,
                                                       "Changed!",
                                                       13,
                                                       "Changed!",
                                                       false,
                                                       false));

            data.add (new WatchData (desc,
                                     new_local,
                                     do_nothing,
                                     config,
                                     section,
                                     setting));
        }

        // add system config back, expect no changes
        {
            var desc = "add system config back, expect no changes";
            var system_default = new SettingsReplace (this,
                                                      new Settings.default ());

            data.add (new WatchData.no_changes (desc,
                                                do_nothing,
                                                system_default));
        }

        // remove several keys from local config, expect changes for those
        {
            var desc = "remove several keys from local config, expect changes" +
                " for those";
            var config = new ConfigSet ();

            config.gee.add (ConfigurationEntry.INTERFACE);

            var section = new SectionMap ();
            var general_section = section.new_values (GENERAL);
            var foo_section = section.new_values (FOO);

            general_section.add (SectionEntry.TITLE);
            foo_section.add (SectionEntry.ENABLED);

            var setting = new SettingMap ();
            var foo_setting = setting.new_values (FOO);

            foo_setting.add ("setting");

            var new_local = new SettingsReplace
                                        (this,
                                         new Settings (null,
                                                       false,
                                                       null,
                                                       13,
                                                       "Changed!",
                                                       null,
                                                       null));

            data.add (new WatchData (desc,
                                     new_local,
                                     do_nothing,
                                     config,
                                     section,
                                     setting));
        }

        // remove local config, expect changes for the rest of settings
        {
            var desc = "remove local config, expect changes for the rest of " +
                "settings";
            var config = new ConfigSet ();

            config.gee.add (ConfigurationEntry.PORT);

            var section = new SectionMap ();
            var general_section = section.new_values (GENERAL);
            var foo_section = section.new_values (FOO);

            general_section.add (SectionEntry.ENABLED);
            foo_section.add (SectionEntry.TITLE);

            var setting = new SettingMap ();

            data.add (new WatchData (desc,
                                     new SettingsRemove (this),
                                     do_nothing,
                                     config,
                                     section,
                                     setting));
        }

        return data;
    }

    private void test_watching () {
        var remover = new ConfigRemover (this);
        assert (remover != null);
        var full_settings = new Settings.default ();
        assert (full_settings != null);

        try {  
            this.set_config (LOCAL_CONFIG,
                             full_settings);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        try {
            this.set_config (SYSTEM_CONFIG,
                             full_settings);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        try {
            this.config = new UserConfig.with_paths (LOCAL_CONFIG, SYSTEM_CONFIG);
        } catch (GLib.Error error) {
            assert_not_reached ();
        }

        assert (this.config != null);
        this.config.configuration_changed.connect
                                        (this.on_configuration_changed);
        this.config.section_changed.connect (this.on_section_changed);
        this.config.setting_changed.connect (this.on_setting_changed);

        // this have to be after setting local and system config
        var watch_data_array = this.prepare_watch_data ();

        foreach (var watch_data in watch_data_array) {
            this.current_watch_data = watch_data;

            this.timeout_id = Timeout.add_seconds (10, () => {
                if (!this.current_watch_data.empty ()) {
                    this.current_watch_data.print_description ();
                    warning ("Test timed out and not all expected changes " +
                             "happened.");
                    this.current_watch_data.print_expectations ();
                    this.fail = true;
                }
                this.timeout_id = 0;
                this.main_loop.quit ();
                return false;
            });

            watch_data.prepare_setup ();
            this.main_loop.run ();
            if (this.fail) {
                return;
            }
        }
    }

    public int run () throws Error {
        test_loading ();
        test_watching ();

        if (this.fail) {
            return 1;
        }
        return 0;
    }

    public static int main (string[] args) {
        var test = new UserConfigTest ();

        try {
            return test.run ();
        } catch (Error e) {
            return 1;
        }
    }
}
