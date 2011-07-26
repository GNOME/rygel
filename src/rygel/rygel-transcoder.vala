/*
 * Copyright (C) 2009 Nokia Corporation.
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

using Gst;
using GUPnP;
using Gee;

/**
 * The base Transcoder class. Each implementation derives from it and must
 * implement get_distance and get_encoding_profile methods.
 */
internal abstract class Rygel.Transcoder : GLib.Object {
    public string mime_type { get; protected set; }
    public string dlna_profile { get; protected set; }
    public Gst.Caps decoder_caps;

    private const string DECODE_BIN = "decodebin2";
    private const string ENCODE_BIN = "encodebin";

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
     * @param src the media item to create the transcoding source for
     * @param src the original (non-transcoding) source
     *
     * @return      the new transcoding source
     */
    public virtual Element create_source (MediaItem item,
                                          Element   src) throws Error {
        dynamic Element decoder = GstUtils.create_element (DECODE_BIN,
                                                           DECODE_BIN);
        dynamic Element encoder = GstUtils.create_element (ENCODE_BIN,
                                                           ENCODE_BIN);

        encoder.profile = this.get_encoding_profile ();

        var bin = new Bin ("transcoder-source");
        bin.add_many (src, decoder, encoder);

        src.link (decoder);

        decoder.pad_added.connect (this.on_decoder_pad_added);
        decoder.autoplug_continue.connect (this.on_autoplug_continue);

        var pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (null, pad);
        bin.add_pad (ghost);

        return bin;
    }

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

    /**
     * Gets the Gst.EncodingProfile for this transcoder.
     *
     * @return      the Gst.EncodingProfile for this transcoder.
     */
    protected abstract EncodingProfile get_encoding_profile ();

    protected bool mime_type_is_a (string mime_type1, string mime_type2) {
        string content_type1 = ContentType.get_mime_type (mime_type1);
        string content_type2 = ContentType.get_mime_type (mime_type2);

        return ContentType.is_a (content_type1, content_type2);
    }

    private bool on_autoplug_continue (Element decodebin,
                                       Pad     new_pad,
                                       Caps    caps) {
        this.decoder_caps = caps;
        return !this.connect_decoder_pad (decodebin, new_pad);
    }

    private void on_decoder_pad_added (Element decodebin, Pad new_pad) {
        this.connect_decoder_pad (decodebin, new_pad);
    }

    private bool connect_decoder_pad (Element decodebin, Pad new_pad) {
        var bin = decodebin.get_parent () as Bin;
        assert (bin != null);

        var encoder = bin.get_by_name (ENCODE_BIN);
        assert (encoder != null);

        Gst.Pad encoder_pad = null;
        encoder_pad = encoder.get_compatible_pad (new_pad, null);
        if (encoder_pad == null) {
            Signal.emit_by_name (encoder,
                                 "request-pad",
                                 new_pad.get_caps (),
                                 out encoder_pad);
        }

        if (encoder_pad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring..",
                   new_pad.name);

            return false;
        } else {
            debug ("pad '%s' with caps '%s' is compatible with '%s'",
                   new_pad.name,
                   this.decoder_caps.to_string (),
                   encoder_pad.name);
        }

        var pad_link_ok = (new_pad.link (encoder_pad) == PadLinkReturn.OK);
        if (!pad_link_ok) {
            warning ("Failed to link pad '%s' to '%s'",
                     new_pad.name,
                     encoder_pad.name);
        }

        return pad_link_ok;
    }
}
