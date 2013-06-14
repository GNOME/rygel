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

using Gst;
using Gst.PbUtils;
using GUPnP;

public errordomain Rygel.GstTranscoderError {
    CANT_TRANSCODE
}

/**
 * The base Transcoder class. Each implementation derives from it and must
 * implement get_distance and get_encoding_profile methods.
 */
internal abstract class Rygel.GstTranscoder : Rygel.Transcoder {
    public string preset { get;
                           protected set;
                           default =  DEFAULT_ENCODING_PRESET; }

    private const string DECODE_BIN = "decodebin";
    private const string ENCODE_BIN = "encodebin";
    private const string DEFAULT_ENCODING_PRESET = "Rygel DLNA preset";

    dynamic Element decoder;
    dynamic Element encoder;

    private bool link_failed;

    public GstTranscoder (string mime_type,
                          string dlna_profile,
                          string extension) {
        GLib.Object (mime_type : mime_type,
                     dlna_profile : dlna_profile,
                     extension : extension);
    }

    public override void constructed () {
        base.constructed ();

        this.link_failed = true;
    }

    /**
     * Creates a transcoding source.
     *
     * @param src the media item to create the transcoding source for
     * @param src the original (non-transcoding) source
     *
     * @return      the new transcoding source
     */
    public override DataSource create_source (MediaItem  item,
                                              DataSource src) throws Error {
        // We can only link GStreamer data sources together
        assert (src is GstDataSource);

        var orig_source = src as GstDataSource;

        this.decoder = GstUtils.create_element (DECODE_BIN,
                                                DECODE_BIN);
        this.encoder = GstUtils.create_element (ENCODE_BIN,
                                                ENCODE_BIN);

        encoder.profile = this.get_encoding_profile ();
        if (encoder.profile == null) {
            var message = _("Could not create a transcoder configuration. Your GStreamer installation might be missing a plug-in");

            throw new GstTranscoderError.CANT_TRANSCODE (message);
        }

        debug ("%s using the following encoding profile:",
               this.get_class ().get_type ().name ());
        GstUtils.dump_encoding_profile (encoder.profile);

        var bin = new Bin ("transcoder-source");
        bin.add_many (orig_source.src, decoder, encoder);

        orig_source.src.link (decoder);

        decoder.pad_added.connect (this.on_decoder_pad_added);
        decoder.autoplug_continue.connect (this.on_autoplug_continue);
        decoder.no_more_pads.connect (this.on_no_more_pads);

        var pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (null, pad);
        bin.add_pad (ghost);

        return new GstDataSource.from_element (bin);
    }

    /**
     * Gets the Gst.EncodingProfile for this transcoder.
     *
     * @return      the Gst.EncodingProfile for this transcoder.
     */
    protected abstract EncodingProfile get_encoding_profile ();

    private bool on_autoplug_continue (Element decodebin,
                                       Pad     new_pad,
                                       Caps    caps) {
        Gst.Pad sinkpad = null;

        Signal.emit_by_name (this.encoder, "request-pad", caps, out sinkpad);
        if (sinkpad == null) {
            return true;
        }

        return false;
    }

    private void on_decoder_pad_added (Element decodebin, Pad new_pad) {
        Gst.Pad sinkpad;

        sinkpad = this.encoder.get_compatible_pad (new_pad, null);

        if (sinkpad == null) {
            var caps = new_pad.query_caps (null);
            Signal.emit_by_name (this.encoder, "request-pad", caps, out sinkpad);
        }

        if (sinkpad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring..",
                   new_pad.name);

            return;
        }

        var pad_link_ok = (new_pad.link (sinkpad) == PadLinkReturn.OK);
        if (!pad_link_ok) {
            warning ("Failed to link pad '%s' to '%s'",
                     new_pad.name,
                     sinkpad.name);
        } else {
            this.link_failed = false;
        }

        return;
    }

    private const string DESCRIPTION = "Encoder and decoder are not " +
                                       "compatible";

    private void on_no_more_pads (Element decodebin) {
        // We haven't found any pads we could link
        if (this.link_failed) {
            // Signalize that error
            var bin = this.encoder.get_parent () as Bin;
            var error = new IOError.FAILED ("Could not link");
            var message = new Message.error (bin,
                                             error,
                                             DESCRIPTION);


            var bus = bin.get_bus ();
            bus.post (message);
        }
    }
}
