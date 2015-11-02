/*
 * Copyright (C) 2008 Nokia Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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

/**
 * Holds information about an icon.
 */
public class Rygel.IconInfo {
    public string mime_type;
    public string uri;
    public string file_extension;

    public int64 size = -1; // Size in bytes
    public int width = -1;  // Width in pixels
    public int height = -1; // Height in pixels
    public int depth = -1;  // depth of pixels in bytes

    public IconInfo (string mime_type, string file_extension) {
        this.mime_type = mime_type;
        this.file_extension = file_extension;
    }
}
