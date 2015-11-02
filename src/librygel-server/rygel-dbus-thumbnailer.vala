/*
 * Copyright (C) 2011 Nokia Corporation.
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

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
private interface Rygel.Tumbler : GLib.Object {
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
    FreeDesktop.DBusObject fdo;

    private const string THUMBNAILER_IFACE =
                                "org.freedesktop.thumbnails.Thumbnailer1";
    private const string THUMBNAILER_SERVICE =
                                "/org/freedesktop/thumbnails/Thumbnailer1";

    private const uint THUMBNAIL_MAX_QUEUE_SIZE = 50;

    public signal void ready (bool available);

    public DbusThumbnailer (string flavor = "normal") throws GLib.Error {
        this.uris = new ArrayList<string> ();
        this.mimes = new ArrayList<string> ();
        this.timeout_id = 0;
        this.flavor = flavor;

        this.fdo = Bus.get_proxy_sync (BusType.SESSION,
                                       FreeDesktop.DBUS_SERVICE,
                                       FreeDesktop.DBUS_OBJECT_PATH);

        this.fdo.list_activatable_names.begin (this.on_activatable_names);
    }

    public void queue_thumbnail_task (string uri, string mime) {
        var file = File.new_for_uri (uri);
        if (!file.is_native ()) {
            return;
        }
        this.uris.add (uri);
        this.mimes.add (mime);

        if (this.timeout_id != 0) {
            Source.remove (this.timeout_id);
            this.timeout_id = 0;
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
        if (this.tumbler == null) {
            // D-Bus service is not ready yet, keep on queuing
            return true;
        }

        debug ("Queueing thumbnail creation for %d files",
               this.uris.size);

        this.tumbler.Queue.begin (this.uris.to_array (),
                                  this.mimes.to_array (),
                                  this.flavor,
                                  "default",
                                  0);

        this.uris.clear ();
        this.mimes.clear ();
        this.timeout_id = 0;

        return false;
    }

    private void on_activatable_names (Object? source, AsyncResult res) {
        try {
            var names = this.fdo.list_activatable_names.end (res);
            if (THUMBNAILER_IFACE in names) {
                this.tumbler = GLib.Bus.get_proxy_sync (BusType.SESSION,
                                                        THUMBNAILER_IFACE,
                                                        THUMBNAILER_SERVICE);
            } else {
                debug (_("No D-Bus thumbnailer service available"));
            }
        } catch (DBusError error) {
            debug ("DBus error while trying to connect to thumbmailer service:"
                   + " %s",
                   error.message);
        } catch (IOError io_error) {
            debug ("I/O error while trying to connect to thumbmailer service:"
                   + " %s",
                   io_error.message);
        }

        this.ready (this.tumbler != null);
    }
}
