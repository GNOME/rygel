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
using GUPnP;
using Gee;

internal abstract class Rygel.Transcoder : GLib.Object {
    public string mime_type { get; protected set; }
    public string dlna_profile { get; protected set; }

    public Transcoder (string mime_type, string dlna_profile) {
        this.mime_type = mime_type;
        this.dlna_profile = dlna_profile;
    }

    public abstract Element create_source (Element src) throws Error;

    public abstract void add_resources (ArrayList<DIDLLiteResource?> resources,
                                        MediaItem                    item,
                                        TranscodeManager             manager)
                                        throws Error;

    public abstract bool can_handle (string mime_type);

    protected bool mime_type_is_a (string mime_type1,
                                          string mime_type2) {
        string content_type1 = g_content_type_from_mime_type (mime_type1);
        string content_type2 = g_content_type_from_mime_type (mime_type2);

        return g_content_type_is_a (content_type1, content_type2);
    }
}

internal abstract class Rygel.TranscoderBin : Gst.Bin {
    protected static Element create_element (string factoryname,
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

    protected void post_error (Error error) {
        Message msg = new Message.error (this, error, error.message);
        this.post_message (msg);
    }
}
