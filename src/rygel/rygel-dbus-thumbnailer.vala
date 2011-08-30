/*
 * Copyright (C) 2011 Nokia Corporation.
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

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
interface Tumbler : GLib.Object {
        public abstract async uint Queue (string[] uris,
                                          string[] mime_types,
                                          string flavor,
                                          string sheduler,
                                          uint handle) throws GLib.IOError;

        public signal void Finished (uint handle);
        public signal void Error (uint handle,
                                  string[] failed_uris,
                                  int error_code,
                                  string message);
}


internal class Rygel.DbusThumbnailer : GLib.Object {
    private Tumbler tumbler;
    private bool is_running  = false;
    private string file_path;

    const string THUMBNAILER_IFACE = "org.freedesktop.thumbnails.Thumbnailer1";
    const string THUMBNAILER_SERVICE =
                                    "/org/freedesktop/thumbnails/Thumbnailer1";

    public signal void generated (string file_path);
    public signal void error (string file_path,
                              int error_code,
                              string message);



    public DbusThumbnailer () throws GLib.IOError {
        this.tumbler = GLib.Bus.get_proxy_sync (BusType.SESSION,
                                                THUMBNAILER_IFACE,
                                                THUMBNAILER_SERVICE);

        tumbler.Finished.connect (on_finished);
        tumbler.Error.connect (on_error);
    }

    public async void create_thumbnail_task (string file_path,
                                             string mime,
                                             string flavor) {
        string uris[1];
        string mimes[1];

        if (in_progress ()) {
            return;
        }

        this.is_running = true;
        this.file_path = file_path;

        uris[0] = file_path;
        mimes[0] = mime;

        try {
            yield this.tumbler.Queue (uris, mimes, flavor, "default", 0);
        } catch (GLib.IOError e) {}
    }

    public bool in_progress () {
        return this.is_running;
    }

    private void on_finished (uint handle) {
        generated (this.file_path);
        this.is_running = false;
    }

    private void on_error (uint handle,
                           string[] failed_uris,
                           int error_code,
                           string message) {
        error (this.file_path, error_code, message);
    }
}
