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

/**
 * Responsible for management of all transcoders:
 *    - gets the appropriate transcoder given a transcoding target.
 *    - provide all possible transcoding resources for items.
 */
internal abstract class Rygel.TranscodeManager : GLib.Object {
    private ArrayList<Transcoder> transcoders;

    public TranscodeManager () {
        transcoders = new ArrayList<Transcoder> ();

        var config = Configuration.get_default ();

        if (config.transcoding) {
            if (config.lpcm_transcoder) {
                transcoders.add (new L16Transcoder (Endianness.BIG));
            }
            if (config.mp3_transcoder) {
                transcoders.add (new MP3Transcoder (MP3Layer.THREE));
            }
            if (config.mp2ts_transcoder) {
                transcoders.add (new MP2TSTranscoder(MP2TSProfile.SD));
                transcoders.add (new MP2TSTranscoder(MP2TSProfile.HD));
            }
        }
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
        }

        // First add resource of the transcoders that are primarily meant for
        // the UPnP class of the item concerned
        foreach (var transcoder in this.transcoders) {
            if (item.upnp_class.has_prefix (transcoder.upnp_class)) {
                transcoder.add_resources (resources, item, this);
            }
        }

        // Then add resources from other transcoders
        foreach (var transcoder in this.transcoders) {
            if (!item.upnp_class.has_prefix (transcoder.upnp_class)) {
                transcoder.add_resources (resources, item, this);
            }
        }
    }

    public Transcoder get_transcoder (string  target) throws Error {
        Transcoder transcoder = null;

        foreach (var iter in this.transcoders) {
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
}

