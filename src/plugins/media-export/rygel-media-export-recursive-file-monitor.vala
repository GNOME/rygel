/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
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

public class Rygel.MediaExport.RecursiveFileMonitor : Object {
    private Cancellable        cancellable;
    HashMap<File, FileMonitor> monitors;
    bool                       monitor_changes;

    public RecursiveFileMonitor (Cancellable? cancellable) {
        this.monitor_changes = true;
        var config = MetaConfig.get_default ();
        config.setting_changed.connect (this.on_config_changed);
        this.on_config_changed (config, Plugin.NAME, "monitor-changes");

        if (!this.monitor_changes) {
            message (_("Will not monitor file changes"));
        }

        this.cancellable = cancellable;
        this.monitors = new HashMap<File, FileMonitor> ((HashDataFunc<File>) File.hash,
                                                        (EqualDataFunc<File>) File.equal);
        if (cancellable != null) {
            cancellable.cancelled.connect (this.cancel);
        }
    }

    public void on_monitor_changed (File             file,
                                    File?            other_file,
                                    FileMonitorEvent event_type) {
        if (this.monitor_changes) {
            this.changed (file, other_file, event_type);
        }

        switch (event_type) {
            case FileMonitorEvent.CREATED:
                this.add.begin (file);

                break;
            case FileMonitorEvent.DELETED:
                var file_monitor = this.monitors.get (file);
                if (file_monitor != null) {
                    debug ("Folder %s gone; removing watch",
                           file.get_uri ());
                    this.monitors.unset (file);
                    file_monitor.cancel ();
                    file_monitor.changed.disconnect (this.on_monitor_changed);
                }

                break;
            default:
                // do nothing
                break;
        }
    }

    public async void add (File file) {
        if (this.monitors.has_key (file)) {
            return;
        }

        try {
            var info = yield file.query_info_async
                                        (FileAttribute.STANDARD_TYPE,
                                         FileQueryInfoFlags.NONE,
                                         Priority.DEFAULT,
                                         null);
            if (info.get_file_type () != FileType.DIRECTORY) {
                return;
            }

            var file_monitor = file.monitor_directory (FileMonitorFlags.NONE,
                                                       this.cancellable);
            this.monitors.set (file, file_monitor);
            file_monitor.changed.connect (this.on_monitor_changed);
        } catch (Error err) {
            if (err is IOError.NOT_FOUND) {
                debug ("File %s disappeared while trying to get information",
                       file.get_uri ());
            } else if (err is IOError.NOT_SUPPORTED) {
                debug ("File monitoring is not supported for %s",
                       file.get_uri ());
            } else {
                // Avoid warning when file is removed in the meantime, e.g. in
                // upload case.
                warning (_("Failed to setup up file monitor for %s: %s"),
                         file.get_uri (),
                         err.message);
            }
        }
    }

    public void cancel () {
        foreach (var monitor in this.monitors.values) {
            monitor.cancel ();
        }

        this.monitors.clear ();
    }

    public signal void changed (File             file,
                                File?            other_file,
                                FileMonitorEvent event_type);

    private void on_config_changed (Configuration config,
                                    string section,
                                    string key) {
        if (section != Plugin.NAME || key != "monitor-changes") {
            return;
        }

        try {
            this.monitor_changes = config.get_bool (Plugin.NAME,
                                                    "monitor-changes");
        } catch (Error error) { }
    }
}
