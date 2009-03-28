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
using GUPnP;
using Gee;
using Gst;

internal abstract class Rygel.TranscodeManager : GLib.Object {
    private ArrayList<Transcoder> audio_transcoders;
    private ArrayList<Transcoder> video_transcoders;

    public TranscodeManager () {
        audio_transcoders = new ArrayList<Transcoder> ();
        video_transcoders = new ArrayList<Transcoder> ();

        audio_transcoders.add (new L16Transcoder (Endianness.BIG));
        audio_transcoders.add (new MP3Transcoder (MP3Layer.THREE));
        video_transcoders.add (new MP2TSTranscoder(MP2TSProfile.SD));
        video_transcoders.add (new MP2TSTranscoder(MP2TSProfile.HD));
    }

    public abstract string create_uri_for_item (MediaItem  item,
                                                string?    transcode_target,
                                                out string protocol);

    public virtual void add_resources (ArrayList<DIDLLiteResource?> resources,
                                       MediaItem                    item)
                                       throws Error {
        if (item.upnp_class.has_prefix (MediaItem.IMAGE_CLASS)) {
            // No  transcoding for images yet :(
            return;
        } else if (item.upnp_class.has_prefix (MediaItem.MUSIC_CLASS)) {
            this.add_audio_resources (resources, item);
            this.add_video_resources (resources, item);
        } else {
            this.add_video_resources (resources, item);
            this.add_audio_resources (resources, item);
        }
    }

    public Transcoder get_transcoder (string  target) throws Error {
        Transcoder transcoder = null;

        foreach (var iter in this.audio_transcoders) {
            if (iter.can_handle (target)) {
                transcoder = iter;
            }
        }

        foreach (var iter in this.video_transcoders) {
            if (iter.can_handle (target)) {
                transcoder = iter;
            }
        }

        if (transcoder == null) {
            throw new HTTPRequestError.NOT_FOUND (
                            "No transcoder available for target format '%s'",
                            target);
        }

        return transcoder;
    }

    private void add_audio_resources (ArrayList<DIDLLiteResource?> resources,
                                      MediaItem                    item)
                                      throws Error {
        foreach (var transcoder in this.audio_transcoders) {
            transcoder.add_resources (resources, item, this);
        }
    }

    private void add_video_resources (ArrayList<DIDLLiteResource?> resources,
                                      MediaItem                    item)
                                      throws Error {
        foreach (var transcoder in this.video_transcoders) {
            transcoder.add_resources (resources, item, this);
        }
    }
}

