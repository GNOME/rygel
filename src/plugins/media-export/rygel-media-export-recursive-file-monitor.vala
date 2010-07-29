/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
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


using Gee;
using Rygel;

public class Rygel.MediaExport.RecursiveFileMonitor : Object {
    private Cancellable cancellable;
    HashMap<File, FileMonitor> monitors;

    public RecursiveFileMonitor (Cancellable? cancellable) {
        this.cancellable = cancellable;
        this.monitors = new HashMap<File, FileMonitor> (GLib.file_hash,
                                                        GLib.file_equal);
    }

    public void on_monitor_changed (File             file,
                                    File?            other_file,
                                    FileMonitorEvent event_type) {
        this.changed (file, other_file, event_type);

        switch (event_type) {
            case FileMonitorEvent.CREATED:
                this.add (file);

                break;
            case FileMonitorEvent.DELETED:
                var file_monitor = this.monitors.get (file);
                if (file_monitor != null) {
                    debug (_("Directory %s gone, removing watch"),
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
        try {
            var info = yield file.query_info_async (
                                                 FILE_ATTRIBUTE_STANDARD_TYPE,
                                                 FileQueryInfoFlags.NONE,
                                                 Priority.DEFAULT,
                                                 null);
            if (info.get_file_type () == FileType.DIRECTORY) {
                var file_monitor = file.monitor_directory (
                                                         FileMonitorFlags.NONE,
                                                         this.cancellable);
                this.monitors.set (file, file_monitor);
                file_monitor.changed.connect (this.on_monitor_changed);
            }
        } catch (Error err) {
            warning (_("Failed to get file info for %s"), file.get_uri ());
        }
    }

    public void cancel () {
        if (this.cancellable != null) {
            this.cancellable.cancel ();
        } else {
            foreach (var monitor in this.monitors.values) {
                monitor.cancel ();
            }
        }
    }

    public signal void changed (File             file,
                                File?            other_file,
                                FileMonitorEvent event_type);
}
