/*
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
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
using Rygel;
using Gst;

internal abstract class Rygel.GstUtils {
    public static Element create_element (string factoryname,
                                             string? name)
                                             throws Error {
        Element element = ElementFactory.make (factoryname, name);
        if (element == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                "Required element factory '%s' missing",
                                factoryname);
        }

        return element;
    }

    public static void post_error (Element dest, Error error) {
        Message msg = new Message.error (dest, error, error.message);
        dest.post_message (msg);
    }
}
