/*
 * Copyright (C) 2009 Jens Georg <mail@jensge.org>.
 *
 * Author: Jens Georg <mail@jensge.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using Gee;
using Rygel;

public class Rygel.MediaExportRecursiveFileMonitor : Object {
    private Cancellable cancellable;
    HashMap<File, FileMonitor> monitors;

    public MediaExportRecursiveFileMonitor (Cancellable? cancellable) {
        this.cancellable = cancellable;
        this.monitors = new HashMap<File, FileMonitor> (GLib.file_hash,
                                                        GLib.file_equal);
    }

    public void on_monitor_changed (File             file,
                                    File?            other_file,
                                    FileMonitorEvent event_type) {
        changed (file, other_file, event_type);

        switch (event_type) {
            case FileMonitorEvent.CREATED:
                this.monitor (file);
                break;
            case FileMonitorEvent.DELETED:
                var file_monitor = this.monitors.get (file);
                if (file_monitor != null) {
                    debug ("Directory %s gone, removing watch",
                           file.get_uri ());
                    this.monitors.remove (file);
                    file_monitor.cancel ();
                    file_monitor.changed.disconnect (this.on_monitor_changed);
                }
                break;
            default:
                // do nothing
                break;
        }
    }

    private void on_info_ready (Object source, AsyncResult res) {
        var file = (File) source;

        try {
            var info = file.query_info_finish (res);
            if (info.get_file_type () == FileType.DIRECTORY) {
                var file_monitor = file.monitor_directory (
                                                         FileMonitorFlags.NONE,
                                                         this.cancellable);
                this.monitors.set (file, file_monitor);
                file_monitor.changed.connect (this.on_monitor_changed);
            }
        } catch (Error error) {
            warning ("Failed to get file info for %s",
                     file.get_uri ());
        }
    }

    public void monitor (File file) {
        file.query_info_async (FILE_ATTRIBUTE_STANDARD_TYPE,
                               FileQueryInfoFlags.NONE,
                               Priority.DEFAULT,
                               null,
                               this.on_info_ready);
    }

    public void cancel () {
        if (this.cancellable != null) {
            this.cancellable.cancel ();
        } else {
            foreach (var monitor in this.monitors.get_values ()) {
                monitor.cancel ();
            }
        }
    }

    public signal void changed (File             file,
                                File?            other_file,
                                FileMonitorEvent event_type);
}
