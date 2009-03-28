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

/**
 * The base Transcoder class. Each implementation derives from it and must
 * at least implement create_source method.
 */
internal abstract class Rygel.Transcoder : GLib.Object {
    public string mime_type { get; protected set; }
    public string dlna_profile { get; protected set; }

    // Primary UPnP item class that this transcoder is meant for, doesn't
    // necessarily mean it cant be used for other classes.
    public string upnp_class { get; protected set; }

    public Transcoder (string mime_type,
                       string dlna_profile,
                       string upnp_class) {
        this.mime_type = mime_type;
        this.dlna_profile = dlna_profile;
        this.upnp_class = upnp_class;
    }

    /**
     * Creates a transcoding source.
     *
     * @param src the original (non-transcoding) source
     *
     * @return      the new transcoding source
     */
    public abstract Element create_source (Element src) throws Error;

    public void add_resources (ArrayList<DIDLLiteResource?> resources,
                               MediaItem                    item,
                               TranscodeManager             manager)
                               throws Error {
        if (this.mime_type_is_a (item.mime_type, this.mime_type)) {
            return;
        }

        resources.add (this.create_resource (item, manager));
    }

    public virtual DIDLLiteResource create_resource (MediaItem        item,
                                                     TranscodeManager manager)
                                                     throws Error {
        string protocol;
        var uri = manager.create_uri_for_item (item,
                                               this.dlna_profile,
                                               out protocol);
        DIDLLiteResource res = item.create_res (uri);
        res.mime_type = this.mime_type;
        res.protocol = protocol;
        res.dlna_profile = this.dlna_profile;
        res.dlna_conversion = DLNAConversion.TRANSCODED;
        res.dlna_flags = DLNAFlags.STREAMING_TRANSFER_MODE;
        res.dlna_operation = DLNAOperation.NONE;
        res.size = -1;

        return res;
    }

    public bool can_handle (string target) {
        return target == this.dlna_profile;
    }

    protected bool mime_type_is_a (string mime_type1,
                                          string mime_type2) {
        string content_type1 = g_content_type_from_mime_type (mime_type1);
        string content_type2 = g_content_type_from_mime_type (mime_type2);

        return g_content_type_is_a (content_type1, content_type2);
    }
}

