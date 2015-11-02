/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2010-2011 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

internal errordomain ThumbnailerError {
    NO_DIR,
    NO_THUMBNAIL
}

/**
 * Provides thumbnails for images and videos.
 */
internal class Rygel.Thumbnailer : GLib.Object {
    private static Thumbnailer thumbnailer; // Our singleton object
    private static bool first_time = true;

    private Thumbnail template;
    private string extension;

    private DbusThumbnailer thumbler = null;

    private Thumbnailer () throws ThumbnailerError {
        this.template = new Thumbnail ("image/png", "PNG_TN", "png");
        this.template.width = 128;
        this.template.height = 128;
        this.template.depth = 24;
        this.extension = "." + this.template.file_extension;

        try {
            this.thumbler = new DbusThumbnailer ();
            this.thumbler.ready.connect (this.on_dbus_thumbnailer_ready);
        } catch (Error error) {}
    }

    public static Thumbnailer? get_default () {
        if (first_time) {
            try {
                thumbnailer = new Thumbnailer ();
            } catch (ThumbnailerError err) {
                warning (_("No thumbnailer available: %s"), err.message);
            }

            first_time = false;
        }

        return thumbnailer;
    }

    public Thumbnail get_thumbnail (string uri, string? mime_type) throws Error {
        var file = File.new_for_uri (uri);
        if (!file.is_native ()) {
            throw new ThumbnailerError.NO_THUMBNAIL
                                        (_("Thumbnailing not supported"));
        }

        var info = file.query_info (FileAttribute.THUMBNAIL_PATH + "," +
                                    FileAttribute.THUMBNAILING_FAILED,
                                    FileQueryInfoFlags.NONE);
        var path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
        var failed = info.get_attribute_boolean
                                        (FileAttribute.THUMBNAILING_FAILED);

        if (failed) {
            // Thumbnailing failed previously, so there's no current thumbnail
            // and it doesn't make any sense to request one.
            throw new ThumbnailerError.NO_THUMBNAIL
                                        (_("No thumbnail available"));
        }

        // Send a request to create thumbnail if it does not exist, signal
        // that there's no thumbnail available now.
        if (this.thumbler != null && path == null && mime_type != null) {
            this.thumbler.queue_thumbnail_task (uri, mime_type);

            throw new ThumbnailerError.NO_THUMBNAIL
                                        (_("No thumbnail available. Generation requested."));
        }

        if (path == null) {
            throw new ThumbnailerError.NO_THUMBNAIL
                                        (_("No thumbnail available"));
        }

        file = File.new_for_path (path);
        info = file.query_info (FileAttribute.ACCESS_CAN_READ + "," +
                                FileAttribute.STANDARD_SIZE,
                                FileQueryInfoFlags.NONE,
                                null);

        if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)) {
            throw new ThumbnailerError.NO_THUMBNAIL
                                        (_("No thumbnail available"));
        }

        var thumbnail = new Thumbnail (this.template.mime_type,
                                       this.template.dlna_profile,
                                       this.template.file_extension);
        thumbnail.width = this.template.width;
        thumbnail.height = this.template.height;
        thumbnail.depth = this.template.depth;
        thumbnail.uri = Filename.to_uri (path, null);
        thumbnail.size = (int64) info.get_attribute_uint64
                                        (FileAttribute.STANDARD_SIZE);

        return thumbnail;
    }

    private void on_dbus_thumbnailer_ready (bool available) {
        if (!available) {
            this.thumbler = null;
            message (_("No D-Bus thumbnailer available"));
        }
    }
}
