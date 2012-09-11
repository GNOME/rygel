/*
 * Copyright (C) 2009-2012 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
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

using GUPnP;

/**
 * The base Transcoder class. Each implementation derives from it and must
 * implement get_distance.
 */
public abstract class Rygel.Transcoder : GLib.Object {
    public string mime_type { get; protected set; }
    public string dlna_profile { get; protected set; }
    public string extension { get; protected set; }

    /**
     * Creates a transcoding source.
     *
     * @param src the media item to create the transcoding source for
     * @param src the original (non-transcoding) source
     *
     * @return      the new transcoding source
     */
    public abstract DataSource create_source (MediaItem  item,
                                              DataSource src) throws Error;

    public virtual DIDLLiteResource? add_resource (DIDLLiteItem     didl_item,
                                                   MediaItem        item,
                                                   TranscodeManager manager)
                                                   throws Error {
        if (this.mime_type_is_a (item.mime_type, this.mime_type) &&
            this.dlna_profile == item.dlna_profile) {
            return null;
        }

        var protocol = manager.get_protocol ();
        var uri = manager.create_uri_for_item (item,
                                               -1,
                                               -1,
                                               this.dlna_profile);
        var res = item.add_resource (didl_item, uri, protocol);
        res.size = -1;

        var protocol_info = res.protocol_info;
        protocol_info.mime_type = this.mime_type;
        protocol_info.dlna_profile = this.dlna_profile;
        protocol_info.dlna_conversion = DLNAConversion.TRANSCODED;
        protocol_info.dlna_flags = DLNAFlags.STREAMING_TRANSFER_MODE |
                                   DLNAFlags.BACKGROUND_TRANSFER_MODE |
                                   DLNAFlags.CONNECTION_STALL |
                                   DLNAFlags.DLNA_V15;
        if (item is AudioItem && (item as AudioItem).duration > 0) {
            protocol_info.dlna_operation = DLNAOperation.TIMESEEK;
        } else {
            protocol_info.dlna_operation = DLNAOperation.NONE;
        }

        return res;
    }

    public bool can_handle (string target) {
        return target == this.dlna_profile;
    }

    /**
     * Gets the numeric value that gives an gives an estimate of how hard
     * would it be to trancode @item to target profile of this transcoder.
     *
     * @param item the media item to calculate the distance for
     *
     * @return      the distance from the @item, uint.MIN if providing such a
     *              value is impossible or uint.MAX if it doesn't make any
     *              sense to use this transcoder for @item
     */
    public abstract uint get_distance (MediaItem item);

    protected bool mime_type_is_a (string mime_type1, string mime_type2) {
        string content_type1 = ContentType.get_mime_type (mime_type1);
        string content_type2 = ContentType.get_mime_type (mime_type2);

        return ContentType.is_a (content_type1, content_type2);
    }
}
