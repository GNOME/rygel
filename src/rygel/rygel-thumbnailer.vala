/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Gst;

internal errordomain ThumbnailerError {
    NO_DIR,
    NO_THUMBNAIL
}

/**
 * Provides thumbnails for images and vidoes.
 */
internal class Rygel.Thumbnailer : GLib.Object {
    private static Thumbnailer thumbnailer; // Our singleton object
    private static bool first_time = true;

    public string directory;

    private Thumbnail template;
    private string extension;

    private Thumbnailer () throws ThumbnailerError {
        var dir = Path.build_filename (Environment.get_home_dir (),
                                       ".thumbnails",
                                       "cropped");
        var file = File.new_for_path (dir);
        this.template = new Thumbnail ();

        if (!file.query_exists (null)) {
            dir = Path.build_filename (Environment.get_home_dir (),
                                       ".thumbnails",
                                       "normal");
            file = File.new_for_path (dir);

            if (!file.query_exists (null)) {
                var message = _("Failed to find thumbnails folder.");

                throw new ThumbnailerError.NO_DIR (message);
            } else {
                this.template.mime_type = "image/png";
                this.template.dlna_profile = "PNG_TN";
                this.template.width = 128;
                this.template.height = 128;
                this.template.depth = 32;
                this.extension = ".png";
            }
        } else {
            this.template.width = 124;
            this.template.height = 124;
            this.template.depth = 24;
            this.extension = ".jpeg";
        }

        this.directory = dir;
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

    public Thumbnail get_thumbnail (string uri) throws Error {
        Thumbnail thumbnail = null;

        var path = Checksum.compute_for_string (ChecksumType.MD5, uri) +
                   this.extension;
        var full_path = Path.build_filename (this.directory, path);
        var file = File.new_for_path (full_path);

        var info = file.query_info (FILE_ATTRIBUTE_ACCESS_CAN_READ + "," +
                                    FILE_ATTRIBUTE_STANDARD_SIZE,
                                    FileQueryInfoFlags.NONE,
                                    null);

        if (!info.get_attribute_boolean (FILE_ATTRIBUTE_ACCESS_CAN_READ)) {
            throw new ThumbnailerError.NO_THUMBNAIL (
                                        _("No thumbnail available"));
        }

        thumbnail = new Thumbnail ();
        thumbnail.width = this.template.width;
        thumbnail.height = this.template.height;
        thumbnail.depth = this.template.depth;
        thumbnail.uri = Filename.to_uri (full_path, null);
        thumbnail.size = (long) info.get_attribute_uint64 (
                                        FILE_ATTRIBUTE_STANDARD_SIZE);

        return thumbnail;
    }
}
