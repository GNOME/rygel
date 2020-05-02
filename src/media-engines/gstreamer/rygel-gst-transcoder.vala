/*
 * Copyright (C) 2009-2012 Nokia Corporation.
 * Copyright (C) 2012 Intel Corporation.
 * Copyright (C) 2013 Cable Television Laboratories, Inc.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *         Jens Georg <jensg@openismus.com>
 *         Prasanna Modem <prasanna@ecaspia.com>
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

using Gst;
using Gst.PbUtils;
using GUPnP;

public errordomain Rygel.GstTranscoderError {
    CANT_TRANSCODE
}

/**
 * The base Transcoder class used by gstreamer media engine.
 * Each implementation derives from it and must
 * implement get_resources_for_item and get_encoding_profile methods.
 */
internal abstract class Rygel.GstTranscoder : GLib.Object {
    private const string DEFAULT_ENCODING_PRESET = "Rygel DLNA preset";

    public string name { get; construct; }
    public string mime_type { get; construct; }
    public string dlna_profile { get; construct; }
    public string extension { get; construct; }

    public string preset { get;
                           protected set;
                           default =  DEFAULT_ENCODING_PRESET; }


    protected GstTranscoder (string name,
                             string mime_type,
                             string dlna_profile,
                             string extension) {
        GLib.Object (name : name,
                     mime_type : mime_type,
                     dlna_profile : dlna_profile,
                     extension : extension);
    }

    public override void constructed () {
        base.constructed ();
    }

    /**
     * Get the supported (transcoded) MediaResource for the given content item
     *
     * @return A MediaResources or null if the transcoder cannot
     * transcode this media item
     */
    public virtual MediaResource? get_resource_for_item (MediaFileItem item) {
        MediaResource res = new MediaResource(this.name);

        res.mime_type = this.mime_type;
        res.dlna_profile = this.dlna_profile;
        res.extension = this.extension;
        res.dlna_conversion = DLNAConversion.TRANSCODED;
        res.dlna_flags = DLNAFlags.DLNA_V15
                         | DLNAFlags.STREAMING_TRANSFER_MODE
                         | DLNAFlags.BACKGROUND_TRANSFER_MODE
                         | DLNAFlags.CONNECTION_STALL;
        // For transcoded content only support time seek
        res.dlna_operation = DLNAOperation.TIMESEEK;

        // Retrieve the duration from primary media resource
        if (item is AudioItem) {
            res.duration = ((AudioItem) item).duration;
        }

        return res;
    }

    /**
     * Gets a numeric value that gives an gives an estimate of how hard
     * it would be for this transcoder to trancode @item to the target profile of
     * this transcoder.
     *
     * @param item the media item to calculate the distance for
     *
     * @return      the distance from the @item, uint.MIN if providing such a
     *              value is impossible or uint.MAX if it doesn't make any
     *              sense to use this transcoder for @item
     */
    public abstract uint get_distance (MediaFileItem item);

    /**
     * Creates a transcoding source.
     *
     * @param src the media item to create the transcoding source for
     * @param src the original (non-transcoding) source
     *
     * @return      the new transcoding source
     */
    public GstDataSource create_source (MediaFileItem item, DataSource src) throws Error {
        // We can only link GStreamer data sources together
        assert (src is GstDataSource);

        return new TranscodingGstDataSource (src, this.get_encoding_profile (item));
    }

    /**
     * Gets the Gst.EncodingProfile for this transcoder.
     *
     * @return      the Gst.EncodingProfile for this transcoder.
     */
    protected abstract EncodingProfile get_encoding_profile
                                        (MediaFileItem item);

    public bool transcoding_necessary (MediaFileItem item) {
        return !(this.mime_type_is_a (this.mime_type, item.mime_type) &&
                 this.dlna_profile == item.dlna_profile);
    }

    protected bool mime_type_is_a (string mime_type1, string mime_type2) {
        string content_type1 = ContentType.get_mime_type (mime_type1);
        string content_type2 = ContentType.get_mime_type (mime_type2);

        return ContentType.is_a (content_type1, content_type2);
    }

}
