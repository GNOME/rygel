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

internal class Rygel.MP2Transcoder : Gst.Bin {
   private const string DECODEBIN = "decodebin2";
   private const string AUDIO_CONVERT = "audioconvert";
   private const string AUDIO_ENCODER = "twolame";

   private const string AUDIO_SRC_PAD = "audio-src-pad";

   private dynamic Element audio_enc;

   public MP2Transcoder (Element src) throws Error {
        Element decodebin = ElementFactory.make (DECODEBIN, DECODEBIN);
        if (decodebin == null) {
            throw new LiveResponseError.MISSING_PLUGIN (
                                    "Required element '%s' missing", DECODEBIN);
        }

        this.audio_enc = this.create_audio_encoder ();

        this.add_many (src, decodebin, this.audio_enc);
        src.link (decodebin);

        var src_pad = this.audio_enc.get_static_pad (AUDIO_SRC_PAD);
        var ghost = new GhostPad (null, src_pad);
        this.add_pad (ghost);

        decodebin.pad_added += this.decodebin_pad_added;
   }

   private void decodebin_pad_added (Element decodebin,
                                     Pad     new_pad) {
       Pad enc_pad = this.audio_enc.get_compatible_pad (new_pad, null);
       if (enc_pad == null) {
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

   private Element create_audio_encoder () throws Error {
       var convert = ElementFactory.make (AUDIO_CONVERT, AUDIO_CONVERT);
       if (convert == null) {
           throw new LiveResponseError.MISSING_PLUGIN (
                   "Required element '%s' missing",
                   AUDIO_CONVERT);
       }

       var encoder = ElementFactory.make (AUDIO_ENCODER, AUDIO_ENCODER);
       if (encoder == null) {
           throw new LiveResponseError.MISSING_PLUGIN (
                   "Required element '%s' missing",
                   AUDIO_ENCODER);
       }

       var bin = new Bin ("audio-encoder-bin");
       bin.add_many (convert, encoder);

       var filter = Caps.from_string ("audio/x-raw-int");
       convert.link_filtered (encoder, filter);

       var pad = convert.get_static_pad ("sink");
       var ghost = new GhostPad (null, pad);
       bin.add_pad (ghost);

       pad = encoder.get_static_pad ("src");
       ghost = new GhostPad (AUDIO_SRC_PAD, pad);
       bin.add_pad (ghost);

       return bin;
   }

   private void post_error (Error error) {
       Message msg = new Message.error (this, error, error.message);
       this.post_message (msg);
   }
}
