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

internal enum Rygel.MP3Profile {
    LAYER2 = 1,
    LAYER3 = 2
}

internal class Rygel.MP3Transcoder : Gst.Bin {
   private const string DECODEBIN = "decodebin2";
   private const string AUDIO_CONVERT = "audioconvert";
   private const string[] AUDIO_ENCODER = {null, "twolame", "lame"};
   private const string AUDIO_PARSER = "mp3parse";

   private const string AUDIO_SRC_PAD = "audio-src-pad";
   private const string AUDIO_SINK_PAD = "audio-sink-pad";

   private dynamic Element audio_enc;
   private MP3Profile layer;

   public MP3Transcoder (Element src, MP3Profile layer) throws Error {
        this.layer = layer;

        Element decodebin = ElementFactory.make (DECODEBIN, DECODEBIN);
        if (decodebin == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing", DECODEBIN);
        }

        this.audio_enc = MP3Transcoder.create_encoder (this.layer,
                                                       AUDIO_SRC_PAD,
                                                       AUDIO_SINK_PAD);

        this.add_many (src, decodebin, this.audio_enc);
        src.link (decodebin);

        var src_pad = this.audio_enc.get_static_pad (AUDIO_SRC_PAD);
        var ghost = new GhostPad (null, src_pad);
        this.add_pad (ghost);

        decodebin.pad_added += this.decodebin_pad_added;
   }

   private void decodebin_pad_added (Element decodebin,
                                     Pad     new_pad) {
       Pad enc_pad = this.audio_enc.get_pad (AUDIO_SINK_PAD);
       if (enc_pad.is_linked () || !new_pad.can_link (enc_pad)) {
           return;
       }

       if (new_pad.link (enc_pad) != PadLinkReturn.OK) {
           this.post_error (new LiveResponseError.LINK (
                       "Failed to link pad %s to %s",
                       new_pad.name,
                       enc_pad.name));
           return;
       }

       this.audio_enc.sync_state_with_parent ();
   }

   internal static Element create_encoder (MP3Profile layer,
                                           string?    src_pad_name,
                                           string?    sink_pad_name)
                                           throws Error {
       var convert = ElementFactory.make (AUDIO_CONVERT, AUDIO_CONVERT);
       if (convert == null) {
           throw new LiveResponseError.MISSING_PLUGIN (
                   "Required element '%s' missing",
                   AUDIO_CONVERT);
       }

       dynamic Element encoder = ElementFactory.make (AUDIO_ENCODER[layer],
                                                      AUDIO_ENCODER[layer]);
       if (encoder == null) {
           throw new LiveResponseError.MISSING_PLUGIN (
                   "Required element '%s' missing",
                   AUDIO_ENCODER[layer]);
       }

       Element parser = ElementFactory.make (AUDIO_PARSER,
                                             AUDIO_PARSER);
       if (parser == null) {
           throw new LiveResponseError.MISSING_PLUGIN (
                   "Required element '%s' missing",
                   AUDIO_PARSER);
       }

       if (layer == MP3Profile.LAYER3) {
            // Best quality
            encoder.quality = 0;
       }

       encoder.bitrate = 256;

       var bin = new Bin ("audio-encoder-bin");
       bin.add_many (convert, encoder, parser);

       var filter = Caps.from_string ("audio/x-raw-int");
       convert.link_filtered (encoder, filter);
       encoder.link (parser);

       var pad = convert.get_static_pad ("sink");
       var ghost = new GhostPad (sink_pad_name, pad);
       bin.add_pad (ghost);

       pad = parser.get_static_pad ("src");
       ghost = new GhostPad (src_pad_name, pad);
       bin.add_pad (ghost);

       return bin;
   }

   private void post_error (Error error) {
       Message msg = new Message.error (this, error, error.message);
       this.post_message (msg);
   }
}
