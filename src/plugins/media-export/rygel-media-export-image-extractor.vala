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
        int width;
        int height;

        var format = yield Pixbuf.get_file_info_async (file.get_path (),
                                                       null,
                                                       out width,
                                                       out height);

        var mime = format.get_mime_types ()[0];
        // TODO: Use enhanced EXIF information?
        this.serialized_info.insert ("UPnPClass", "s", UPNP_CLASS_PHOTO);
        this.serialized_info.insert ("MimeType", "s", mime);

        this.serialized_info.insert ("VideoWidth", "i", width);
        this.serialized_info.insert ("VideoHeight", "i", height);

        if (mime == "image/png") {
            if (width <= 4096 && height <= 4096) {
                this.serialized_info.insert ("DLNAProfile", "s", "PNG_LRG");
            } else {
                var profile = "PNG_RES_%d_%d".printf (width, height);
                this.serialized_info.insert ("DLNAProfile", "s", profile);
            }
        } else {
            if (width <= 640 && height <= 480) {
                this.serialized_info.insert ("DLNAProfile", "s", "JPG_SM");
            } else if (width <= 1024 && height <= 768) {
                this.serialized_info.insert ("DLNAProfile", "s", "JPG_MED");
            } else if (width <= 4096 && height <= 4096) {
                this.serialized_info.insert ("DLNAProfile", "s", "JPEG_LRG");
            } else {
                var profile = "JPEG_RES_%d_%d".printf (width, height);
                this.serialized_info.insert ("DLNAProfile", "s", profile);
            }
        }
    }
}
