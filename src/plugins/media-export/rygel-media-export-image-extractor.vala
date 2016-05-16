/*
 * Copyright (C) 2016 Jens Georg <mail@jensge.org>
 *
 * Author: Jens Georg <mail@jensge.org>
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

using Gdk;

internal class Rygel.MediaExport.ImageExtractor : Extractor {
    public ImageExtractor (File file) {
        GLib.Object (file : file);
    }

    public override async void run () throws Error {
        yield base.run ();

        int width;
        int height;

        var format = yield Pixbuf.get_file_info_async (file.get_path (),
                                                       null,
                                                       out width,
                                                       out height);

        var mime = format.get_mime_types ()[0];
        // TODO: Use enhanced EXIF information?
        this.serialized_info.insert (Serializer.UPNP_CLASS, "s",
                                     UPNP_CLASS_PHOTO);

        this.serialized_info.insert (Serializer.MIME_TYPE, "s", mime);
        this.serialized_info.insert (Serializer.VIDEO_WIDTH, "i", width);
        this.serialized_info.insert (Serializer.VIDEO_HEIGHT, "i", height);

        string? profile = null;

        if (mime == "image/png") {
            if (width <= 4096 && height <= 4096) {
                profile = "PNG_LRG";
            } else {
                profile = "PNG_RES_%d_%d".printf (width, height);
            }
        } else {
            if (width <= 640 && height <= 480) {
                profile = "JPEG_SM";
            } else if (width <= 1024 && height <= 768) {
                profile = "JPEG_MED";
            } else if (width <= 4096 && height <= 4096) {
                profile = "JPEG_LRG";
            } else {
                profile = "JPEG_RES_%d_%d".printf (width, height);
            }
        }

        this.serialized_info.insert (Serializer.DLNA_PROFILE, "s", profile);
    }
}
