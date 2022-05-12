/*
 * This file is part of Rygel.
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

using Gst;
using Gst.PbUtils;

internal class Rygel.TranscodingGstDataSource : Rygel.GstDataSource {
    private const string DECODE_BIN = "decodebin";
    private const string ENCODE_BIN = "encodebin";

    dynamic Element decoder;
    dynamic Element encoder;
    private bool link_failed = true;
    private GstDataSource orig_source;

    public TranscodingGstDataSource(DataSource src, EncodingProfile profile) throws Error {
        var bin = new Bin ("transcoder-source");
        base.from_element (bin);

        this.orig_source = (GstDataSource) src;

        this.encoder = GstUtils.create_element (ENCODE_BIN, ENCODE_BIN);

        this.encoder.profile = profile;
        if (encoder.profile == null) {
            var message = _("Could not create a transcoder configuration. Your GStreamer installation might be missing a plug-in");

            throw new GstTranscoderError.CANT_TRANSCODE (message);
        }

        bin.add (encoder);
        var pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (null, pad);
        bin.add_pad (ghost);
    }

    public override Gee.List<HTTPResponseElement>? preroll
                                        (HTTPSeekRequest? seek_request,
                                         PlaySpeedRequest? playspeed_request)
                                         throws Error {
        var bin = (Gst.Bin) this.src;

        if (seek_request == null || seek_request is HTTPByteSeekRequest) {
            this.decoder = GstUtils.create_element (DECODE_BIN, DECODE_BIN);
            debug ("%s using the following encoding profile:",
                    this.get_class ().get_type ().name ());
                    GstUtils.dump_encoding_profile (encoder.profile);

            bin.add_many (orig_source.src, decoder);
            orig_source.src.link (decoder);
            orig_source.src.sync_state_with_parent ();
            decoder.sync_state_with_parent ();

            decoder.autoplug_continue.connect (this.on_decode_autoplug_continue);
            decoder.pad_added.connect (this.on_decoder_pad_added);
            decoder.no_more_pads.connect (this.on_no_more_pads);
        } else {
            var time_seek = (HTTPTimeSeekRequest) seek_request;

            var timeline = new GES.Timeline.audio_video ();
            var layer = timeline.append_layer ();
            var clip = new GES.UriClip (this.orig_source.get_uri ());
            clip.in_point = time_seek.start_time * Gst.USECOND;
            clip.duration = time_seek.range_duration * Gst.USECOND;
            layer.add_clip (clip);
            timeline.commit ();
            var gessrc = GstUtils.create_element ("gessrc", "gessrc");
            bin.add (gessrc);
            gessrc.pad_added.connect (this.on_decoder_pad_added);
            gessrc.no_more_pads.connect (this.on_no_more_pads);
            gessrc.set ("timeline", timeline, null);
        }

        return base.preroll (seek_request, playspeed_request);
    }

    public override bool perform_seek () {
        return true;
    }

    private Gst.Pad? get_compatible_sink_pad (Pad pad, Caps caps) {
        var sinkpad = this.encoder.get_compatible_pad (pad, null);

        if (sinkpad == null) {
            Signal.emit_by_name (this.encoder, "request-pad", caps, out sinkpad);
        }

        if (sinkpad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring...",
                   pad.name);
        }

        return sinkpad;
    }

    private bool on_decode_autoplug_continue (Element decodebin,
                                              Pad     new_pad,
                                              Caps    caps) {
        return this.get_compatible_sink_pad (new_pad, caps) == null;
    }

    private void on_decoder_pad_added (Element decodebin, Pad new_pad) {
        var sinkpad = this.get_compatible_sink_pad (new_pad, new_pad.query_caps (null));

        if (sinkpad == null) {
            debug ("No compatible encodebin pad found for pad '%s', ignoring...",
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

        // Check if we have any unlinked sink pads in the encoder...
        var pad_iterator = this.encoder.iterate_pads ();
        bool done = false;
        while (!done) {
            GLib.Value val;
            var res = pad_iterator.next (out val);
            if (res == Gst.IteratorResult.DONE || res == Gst.IteratorResult.ERROR) {
                done = true;
            }
            else if (res == Gst.IteratorResult.OK) {
                var p = (Gst.Pad) val;
                if (!p.is_linked ()) {
                    dynamic Gst.Element src = null;
                    if (p.name.has_prefix ("audio")) {
                        src = Gst.ElementFactory.make ("audiotestsrc", null);
                        src.wave = 4;
                    } else if (p.name.has_prefix ("video")) {
                        src = Gst.ElementFactory.make ("videotestsrc", null);
                        src.pattern = 2;
                    }

                    ((Gst.Bin)this.encoder.get_parent ()).add (src);
                    src.link_pads ("src", this.encoder, p.name);
                    src.sync_state_with_parent ();
                }
            } else if (res == Gst.IteratorResult.RESYNC) {
                pad_iterator.resync ();
            }
        }
    }
}
