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

using Gee;

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
interface Tumbler : GLib.Object {
        public abstract async uint Queue (string[] uris,
                                          string[] mime_types,
                                          string flavor,
                                          string sheduler,
                                          uint handle)
                                          throws GLib.IOError,
                                                 GLib.DBusError;
}

internal class Rygel.DbusThumbnailer : GLib.Object {
    private Tumbler tumbler;
    private ArrayList<string> uris;
    private ArrayList<string> mimes;
    private uint timeout_id;
    private string flavor;

    private const string THUMBNAILER_IFACE =
                                "org.freedesktop.thumbnails.Thumbnailer1";
    private const string THUMBNAILER_SERVICE =
                                "/org/freedesktop/thumbnails/Thumbnailer1";

    private const uint THUMBNAIL_MAX_QUEUE_SIZE = 50;

    public DbusThumbnailer (string flavor = "normal") throws GLib.IOError,
                                                             GLib.DBusError {
        this.uris = new ArrayList<string> ();
        this.mimes = new ArrayList<string> ();
        this.timeout_id = 0;
        this.flavor = flavor;

        this.tumbler = GLib.Bus.get_proxy_sync (BusType.SESSION,
                                                THUMBNAILER_IFACE,
                                                THUMBNAILER_SERVICE);
    }

    public void queue_thumbnail_task (string file_path, string mime) {
        this.uris.add (file_path);
        this.mimes.add (mime);

        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
        }

        if (this.uris.size < THUMBNAIL_MAX_QUEUE_SIZE) {
            // delay update to collect more thumbnail creation requests
            this.timeout_id = Timeout.add (100, this.on_timeout);
        } else {
            // queue has grown quite large, flush directly
            this.on_timeout ();
        }
    }

    private bool on_timeout () {
        debug ("Queueing thumbnail creation for %d files",
               this.uris.size);

        this.tumbler.Queue (this.uris.to_array (),
                            this.mimes.to_array (),
                            this.flavor,
                            "default",
                            0);

        this.uris.clear ();
        this.mimes.clear ();
        this.timeout_id = 0;

        return false;
    }
}
